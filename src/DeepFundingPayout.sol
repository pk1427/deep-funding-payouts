// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Non-upgradeable Merkle ETH pot with a one-shot proposal and juror dispute window.
contract DeepFundingPayout {
    error ZeroAddress();
    error InvalidJurors();
    error DuplicateJuror();
    error RoleConflict();
    error Unauthorized();
    error InvalidState();
    error InvalidResult();
    error InvalidProof();
    error AlreadyClaimed();
    error AmountExceeded();
    error ZeroAmount();
    error TransferFailed();
    uint256 public constant DISPUTE_WINDOW = 3 days;
    uint256 public constant MAX_JURORS = 32;
    address public immutable proposer;
    address[] public jurors;
    mapping(address => bool) public isJuror;
    bytes32 public root;
    uint256 public total;
    uint256 public totalClaimed;
    uint256 public proposedAt;
    bool public finalized;
    bool public disputed;
    uint256 public proposalNonce;
    uint256 public upholdVotes;
    uint256 public rejectVotes;
    mapping(uint256 => mapping(address => bool)) public voted;
    mapping(address => bool) public claimed;
    mapping(address => uint256) public refundableBond;
    address public disputer;
    uint256 public disputeBond;
    uint256 private _status = 1;
    event Funded(address indexed funder, uint256 amount);
    event Proposed(bytes32 indexed root, uint256 total, string resultURI, uint256 deadline);
    event Disputed(address indexed disputer, string evidenceURI, uint256 bond);
    event VoteCast(address indexed juror, bool upheld);
    event DisputeResolved(bool upheld);
    event Finalized(bytes32 indexed root, uint256 total);
    event Claimed(address indexed recipient, uint256 amount);
    event BondCredited(address indexed recipient, uint256 amount);
    event BondWithdrawn(address indexed recipient, uint256 amount);
    modifier nonReentrant() {
        if (_status != 1) revert InvalidState();
        _status = 2;
        _;
        _status = 1;
    }
    modifier onlyProposer() {
        if (msg.sender != proposer) revert Unauthorized();
        _;
    }

    constructor(address proposer_, address[] memory jurors_) {
        if (proposer_ == address(0)) revert ZeroAddress();
        if (jurors_.length == 0 || jurors_.length > MAX_JURORS) revert InvalidJurors();
        proposer = proposer_;
        for (uint256 i; i < jurors_.length; i++) {
            address j = jurors_[i];
            if (j == address(0)) revert ZeroAddress();
            if (j == proposer_) revert RoleConflict();
            if (isJuror[j]) revert DuplicateJuror();
            isJuror[j] = true;
            jurors.push(j);
        }
    }

    function fund() external payable {
        if (msg.value == 0) revert ZeroAmount();
        emit Funded(msg.sender, msg.value);
    }

    /// @dev A proposal cannot be replaced; an upheld dispute is the only way to reopen proposing.
    function propose(bytes32 root_, uint256 total_, string calldata uri) external onlyProposer {
        if (finalized || disputed || proposedAt != 0) revert InvalidState();
        if (root_ == bytes32(0) || total_ == 0 || total_ > address(this).balance) revert InvalidResult();
        root = root_;
        total = total_;
        proposedAt = block.timestamp;
        proposalNonce++;
        emit Proposed(root_, total_, uri, block.timestamp + DISPUTE_WINDOW);
    }

    function dispute(string calldata evidenceURI) external payable {
        if (finalized || disputed || proposedAt == 0 || block.timestamp >= proposedAt + DISPUTE_WINDOW) {
            revert InvalidState();
        }
        if (msg.value == 0) revert ZeroAmount();
        disputed = true;
        disputer = msg.sender;
        disputeBond = msg.value;
        emit Disputed(msg.sender, evidenceURI, msg.value);
    }

    function resolveDispute(bool upheld) external {
        if (finalized || !disputed || !isJuror[msg.sender] || voted[proposalNonce][msg.sender]) revert Unauthorized();
        voted[proposalNonce][msg.sender] = true;
        if (upheld) upholdVotes++;
        else rejectVotes++;
        emit VoteCast(msg.sender, upheld);
        if (upholdVotes <= jurors.length / 2 && rejectVotes <= jurors.length / 2) return;
        disputed = false;
        uint256 bond = disputeBond;
        disputeBond = 0;
        if (upheld) {
            refundableBond[disputer] += bond;
            root = bytes32(0);
            total = 0;
            proposedAt = 0;
            emit BondCredited(disputer, bond);
        }
        disputer = address(0);
        emit DisputeResolved(upheld);
    }

    function finalize() external {
        if (
            finalized || disputed || proposedAt == 0 || block.timestamp < proposedAt + DISPUTE_WINDOW
                || address(this).balance < total
        ) revert InvalidState();
        finalized = true;
        emit Finalized(root, total);
    }

    function leaf(address recipient, uint256 amount) public view returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(block.chainid, address(this), recipient, amount))));
    }

    function claim(address recipient, uint256 amount, bytes32[] calldata proof) external nonReentrant {
        if (!finalized) revert InvalidState();
        if (recipient == address(0) || amount == 0) revert ZeroAmount();
        if (claimed[recipient]) revert AlreadyClaimed();
        if (!verify(leaf(recipient, amount), proof)) revert InvalidProof();
        if (totalClaimed + amount > total) revert AmountExceeded();
        claimed[recipient] = true;
        totalClaimed += amount;
        (bool ok,) = payable(recipient).call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit Claimed(recipient, amount);
    }

    function withdrawBond() external nonReentrant {
        uint256 amount = refundableBond[msg.sender];
        if (amount == 0) revert ZeroAmount();
        refundableBond[msg.sender] = 0;
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        if (!ok) revert TransferFailed();
        emit BondWithdrawn(msg.sender, amount);
    }

    function verify(bytes32 hash, bytes32[] calldata proof) public view returns (bool) {
        for (uint256 i; i < proof.length; i++) {
            bytes32 p = proof[i];
            hash = hash < p ? keccak256(abi.encodePacked(hash, p)) : keccak256(abi.encodePacked(p, hash));
        }
        return hash == root;
    }
}
