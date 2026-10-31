export type Judgment={parent:string;more:string;less:string;ratio:string;signature:string};
export const SCALE=10_000n;
export function dependencyWeights(deps:string[],judgments:Judgment[]){if(!deps.length)return{} as Record<string,bigint>;let s=Object.fromEntries(deps.map(x=>[x,SCALE]))as Record<string,bigint>;for(const j of judgments)if(s[j.more]!==undefined&&s[j.less]!==undefined){let r=BigInt(j.ratio);s[j.more]+=r;s[j.less]+=SCALE/r;}let sum=Object.values(s).reduce((a,b)=>a+b,0n);return Object.fromEntries(deps.map(d=>[d,s[d]*SCALE/sum]));}
