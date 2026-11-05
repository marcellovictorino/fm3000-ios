(function(){"use strict";var An;function u(e,t,n){function i(c,l){if(c._zod||Object.defineProperty(c,"_zod",{value:{def:l,constr:o,traits:new Set},enumerable:!1}),c._zod.traits.has(e))return;c._zod.traits.add(e),t(c,l);const A=o.prototype,m=Object.keys(A);for(let y=0;y<m.length;y++){const I=m[y];I in c||(c[I]=A[I].bind(c))}}const r=n?.Parent??Object;class s extends r{}Object.defineProperty(s,"name",{value:e});function o(c){var l;const A=n?.Parent?new s:this;i(A,c),(l=A._zod).deferred??(l.deferred=[]);for(const m of A._zod.deferred)m();return A}return Object.defineProperty(o,"init",{value:i}),Object.defineProperty(o,Symbol.hasInstance,{value:c=>n?.Parent&&c instanceof n.Parent?!0:c?._zod?.traits?.has(e)}),Object.defineProperty(o,"name",{value:e}),o}class ye extends Error{constructor(){super("Encountered Promise during synchronous parse. Use .parseAsync() instead.")}}class un extends Error{constructor(t){super(`Encountered unidirectional transform during encode: ${t}`),this.name="ZodEncodeError"}}(An=globalThis).__zod_globalConfig??(An.__zod_globalConfig={});const dt=globalThis.__zod_globalConfig;function ne(e){return dt}function dn(e){const t=Object.values(e).filter(i=>typeof i=="number");return Object.entries(e).filter(([i,r])=>t.indexOf(+i)===-1).map(([i,r])=>r)}function ht(e,t){return typeof t=="bigint"?t.toString():t}function Ge(e){return{get value(){{const t=e();return Object.defineProperty(this,"value",{value:t}),t}}}}function ft(e){return e==null}function pt(e){const t=e.startsWith("^")?1:0,n=e.endsWith("$")?e.length-1:e.length;return e.slice(t,n)}function Lr(e,t){const n=e/t,i=Math.round(n),r=Number.EPSILON*Math.max(Math.abs(n),1);return Math.abs(n-i)<r?0:n-i}const hn=Symbol("evaluating");function E(e,t,n){let i;Object.defineProperty(e,t,{get(){if(i!==hn)return i===void 0&&(i=hn,i=n()),i},set(r){Object.defineProperty(e,t,{value:r})},configurable:!0})}function he(e,t,n){Object.defineProperty(e,t,{value:n,writable:!0,enumerable:!0,configurable:!0})}function le(...e){const t={};for(const n of e){const i=Object.getOwnPropertyDescriptors(n);Object.assign(t,i)}return Object.defineProperties({},t)}function fn(e){return JSON.stringify(e)}function Pr(e){return e.toLowerCase().trim().replace(/[^\w\s-]/g,"").replace(/[\s_-]+/g,"-").replace(/^-+|-+$/g,"")}const pn="captureStackTrace"in Error?Error.captureStackTrace:(...e)=>{};function Re(e){return typeof e=="object"&&e!==null&&!Array.isArray(e)}const Hr=Ge(()=>{if(dt.jitless||typeof navigator<"u"&&navigator?.userAgent?.includes("Cloudflare"))return!1;try{const e=Function;return new e(""),!0}catch{return!1}});function ve(e){if(Re(e)===!1)return!1;const t=e.constructor;if(t===void 0||typeof t!="function")return!0;const n=t.prototype;return!(Re(n)===!1||Object.prototype.hasOwnProperty.call(n,"isPrototypeOf")===!1)}function mn(e){return ve(e)?{...e}:Array.isArray(e)?[...e]:e instanceof Map?new Map(e):e instanceof Set?new Set(e):e}const qr=new Set(["string","number","symbol"]);function ke(e){return e.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}function Ae(e,t,n){const i=new e._zod.constr(t??e._zod.def);return(!t||n?.parent)&&(i._zod.parent=e),i}function k(e){const t=e;if(!t)return{};if(typeof t=="string")return{error:()=>t};if(t?.message!==void 0){if(t?.error!==void 0)throw new Error("Cannot specify both `message` and `error` params");t.error=t.message}return delete t.message,typeof t.error=="string"?{...t,error:()=>t.error}:t}function jr(e){return Object.keys(e).filter(t=>e[t]._zod.optin==="optional"&&e[t]._zod.optout==="optional")}const Vr={safeint:[Number.MIN_SAFE_INTEGER,Number.MAX_SAFE_INTEGER],int32:[-2147483648,2147483647],uint32:[0,4294967295],float32:[-34028234663852886e22,34028234663852886e22],float64:[-Number.MAX_VALUE,Number.MAX_VALUE]};function Xr(e,t){const n=e._zod.def,i=n.checks;if(i&&i.length>0)throw new Error(".pick() cannot be used on object schemas containing refinements");const s=le(e._zod.def,{get shape(){const o={};for(const c in t){if(!(c in n.shape))throw new Error(`Unrecognized key: "${c}"`);t[c]&&(o[c]=n.shape[c])}return he(this,"shape",o),o},checks:[]});return Ae(e,s)}function $r(e,t){const n=e._zod.def,i=n.checks;if(i&&i.length>0)throw new Error(".omit() cannot be used on object schemas containing refinements");const s=le(e._zod.def,{get shape(){const o={...e._zod.def.shape};for(const c in t){if(!(c in n.shape))throw new Error(`Unrecognized key: "${c}"`);t[c]&&delete o[c]}return he(this,"shape",o),o},checks:[]});return Ae(e,s)}function eo(e,t){if(!ve(t))throw new Error("Invalid input to extend: expected a plain object");const n=e._zod.def.checks;if(n&&n.length>0){const s=e._zod.def.shape;for(const o in t)if(Object.getOwnPropertyDescriptor(s,o)!==void 0)throw new Error("Cannot overwrite keys on object schemas containing refinements. Use `.safeExtend()` instead.")}const r=le(e._zod.def,{get shape(){const s={...e._zod.def.shape,...t};return he(this,"shape",s),s}});return Ae(e,r)}function to(e,t){if(!ve(t))throw new Error("Invalid input to safeExtend: expected a plain object");const n=le(e._zod.def,{get shape(){const i={...e._zod.def.shape,...t};return he(this,"shape",i),i}});return Ae(e,n)}function no(e,t){if(e._zod.def.checks?.length)throw new Error(".merge() cannot be used on object schemas containing refinements. Use .safeExtend() instead.");const n=le(e._zod.def,{get shape(){const i={...e._zod.def.shape,...t._zod.def.shape};return he(this,"shape",i),i},get catchall(){return t._zod.def.catchall},checks:t._zod.def.checks??[]});return Ae(e,n)}function io(e,t,n){const r=t._zod.def.checks;if(r&&r.length>0)throw new Error(".partial() cannot be used on object schemas containing refinements");const o=le(t._zod.def,{get shape(){const c=t._zod.def.shape,l={...c};if(n)for(const A in n){if(!(A in c))throw new Error(`Unrecognized key: "${A}"`);n[A]&&(l[A]=e?new e({type:"optional",innerType:c[A]}):c[A])}else for(const A in c)l[A]=e?new e({type:"optional",innerType:c[A]}):c[A];return he(this,"shape",l),l},checks:[]});return Ae(t,o)}function ro(e,t,n){const i=le(t._zod.def,{get shape(){const r=t._zod.def.shape,s={...r};if(n)for(const o in n){if(!(o in s))throw new Error(`Unrecognized key: "${o}"`);n[o]&&(s[o]=new e({type:"nonoptional",innerType:r[o]}))}else for(const o in r)s[o]=new e({type:"nonoptional",innerType:r[o]});return he(this,"shape",s),s}});return Ae(t,i)}function Ie(e,t=0){if(e.aborted===!0)return!0;for(let n=t;n<e.issues.length;n++)if(e.issues[n]?.continue!==!0)return!0;return!1}function oo(e,t=0){if(e.aborted===!0)return!0;for(let n=t;n<e.issues.length;n++)if(e.issues[n]?.continue===!1)return!0;return!1}function xe(e,t){return t.map(n=>{var i;return(i=n).path??(i.path=[]),n.path.unshift(e),n})}function Me(e){return typeof e=="string"?e:e?.message}function ie(e,t,n){const i=e.message?e.message:Me(e.inst?._zod.def?.error?.(e))??Me(t?.error?.(e))??Me(n.customError?.(e))??Me(n.localeError?.(e))??"Invalid input",{inst:r,continue:s,input:o,...c}=e;return c.path??(c.path=[]),c.message=i,t?.reportInput&&(c.input=o),c}function mt(e){return Array.isArray(e)?"array":typeof e=="string"?"string":"unknown"}function Qe(...e){const[t,n,i]=e;return typeof t=="string"?{message:t,code:"custom",input:n,inst:i}:{...t}}const gn=(e,t)=>{e.name="$ZodError",Object.defineProperty(e,"_zod",{value:e._zod,enumerable:!1}),Object.defineProperty(e,"issues",{value:t,enumerable:!1}),e.message=JSON.stringify(t,ht,2),Object.defineProperty(e,"toString",{value:()=>e.message,enumerable:!1})},wn=u("$ZodError",gn),bn=u("$ZodError",gn,{Parent:Error});function ao(e,t=n=>n.message){const n={},i=[];for(const r of e.issues)r.path.length>0?(n[r.path[0]]=n[r.path[0]]||[],n[r.path[0]].push(t(r))):i.push(t(r));return{formErrors:i,fieldErrors:n}}function so(e,t=n=>n.message){const n={_errors:[]},i=(r,s=[])=>{for(const o of r.issues)if(o.code==="invalid_union"&&o.errors.length)o.errors.map(c=>i({issues:c},[...s,...o.path]));else if(o.code==="invalid_key")i({issues:o.issues},[...s,...o.path]);else if(o.code==="invalid_element")i({issues:o.issues},[...s,...o.path]);else{const c=[...s,...o.path];if(c.length===0)n._errors.push(t(o));else{let l=n,A=0;for(;A<c.length;){const m=c[A];A===c.length-1?(l[m]=l[m]||{_errors:[]},l[m]._errors.push(t(o))):l[m]=l[m]||{_errors:[]},l=l[m],A++}}}};return i(e),n}const gt=e=>(t,n,i,r)=>{const s=i?{...i,async:!1}:{async:!1},o=t._zod.run({value:n,issues:[]},s);if(o instanceof Promise)throw new ye;if(o.issues.length){const c=new(r?.Err??e)(o.issues.map(l=>ie(l,s,ne())));throw pn(c,r?.callee),c}return o.value},wt=e=>async(t,n,i,r)=>{const s=i?{...i,async:!0}:{async:!0};let o=t._zod.run({value:n,issues:[]},s);if(o instanceof Promise&&(o=await o),o.issues.length){const c=new(r?.Err??e)(o.issues.map(l=>ie(l,s,ne())));throw pn(c,r?.callee),c}return o.value},Je=e=>(t,n,i)=>{const r=i?{...i,async:!1}:{async:!1},s=t._zod.run({value:n,issues:[]},r);if(s instanceof Promise)throw new ye;return s.issues.length?{success:!1,error:new(e??wn)(s.issues.map(o=>ie(o,r,ne())))}:{success:!0,data:s.value}},co=Je(bn),Ye=e=>async(t,n,i)=>{const r=i?{...i,async:!0}:{async:!0};let s=t._zod.run({value:n,issues:[]},r);return s instanceof Promise&&(s=await s),s.issues.length?{success:!1,error:new e(s.issues.map(o=>ie(o,r,ne())))}:{success:!0,data:s.value}},lo=Ye(bn),Ao=e=>(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return gt(e)(t,n,r)},uo=e=>(t,n,i)=>gt(e)(t,n,i),ho=e=>async(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return wt(e)(t,n,r)},fo=e=>async(t,n,i)=>wt(e)(t,n,i),po=e=>(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return Je(e)(t,n,r)},mo=e=>(t,n,i)=>Je(e)(t,n,i),go=e=>async(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return Ye(e)(t,n,r)},wo=e=>async(t,n,i)=>Ye(e)(t,n,i),bo=/^[cC][0-9a-z]{6,}$/,yo=/^[0-9a-z]+$/,vo=/^[0-9A-HJKMNP-TV-Za-hjkmnp-tv-z]{26}$/,ko=/^[0-9a-vA-V]{20}$/,Io=/^[A-Za-z0-9]{27}$/,xo=/^[a-zA-Z0-9_-]{21}$/,So=/^P(?:(\d+W)|(?!.*W)(?=\d|T\d)(\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+([.,]\d+)?S)?)?)$/,Co=/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$/,yn=e=>e?new RegExp(`^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-${e}[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$`):/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)$/,Eo=/^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$/,Bo="^(\\p{Extended_Pictographic}|\\p{Emoji_Component})+$";function _o(){return new RegExp(Bo,"u")}const Do=/^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$/,No=/^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$/,Fo=/^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\/([0-9]|[1-2][0-9]|3[0-2])$/,Zo=/^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|::|([0-9a-fA-F]{1,4})?::([0-9a-fA-F]{1,4}:?){0,6})\/(12[0-8]|1[01][0-9]|[1-9]?[0-9])$/,Ro=/^$|^(?:[0-9a-zA-Z+/]{4})*(?:(?:[0-9a-zA-Z+/]{2}==)|(?:[0-9a-zA-Z+/]{3}=))?$/,vn=/^[A-Za-z0-9_-]*$/,Qo=/^https?$/,Oo=/^\+[1-9]\d{6,14}$/,kn="(?:(?:\\d\\d[2468][048]|\\d\\d[13579][26]|\\d\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\d|30)|(?:02)-(?:0[1-9]|1\\d|2[0-8])))",Uo=new RegExp(`^${kn}$`);function In(e){const t="(?:[01]\\d|2[0-3]):[0-5]\\d";return typeof e.precision=="number"?e.precision===-1?`${t}`:e.precision===0?`${t}:[0-5]\\d`:`${t}:[0-5]\\d\\.\\d{${e.precision}}`:`${t}(?::[0-5]\\d(?:\\.\\d+)?)?`}function Wo(e){return new RegExp(`^${In(e)}$`)}function zo(e){const t=In({precision:e.precision}),n=["Z"];e.local&&n.push(""),e.offset&&n.push("([+-](?:[01]\\d|2[0-3]):[0-5]\\d)");const i=`${t}(?:${n.join("|")})`;return new RegExp(`^${kn}T(?:${i})$`)}const Ko=e=>{const t=e?`[\\s\\S]{${e?.minimum??0},${e?.maximum??""}}`:"[\\s\\S]*";return new RegExp(`^${t}$`)},To=/^-?\d+$/,xn=/^-?\d+(?:\.\d+)?$/,Go=/^(?:true|false)$/i,Mo=/^null$/i,Jo=/^undefined$/i,Yo=/^[^A-Z]*$/,Lo=/^[^a-z]*$/,Y=u("$ZodCheck",(e,t)=>{var n;e._zod??(e._zod={}),e._zod.def=t,(n=e._zod).onattach??(n.onattach=[])}),Sn={number:"number",bigint:"bigint",object:"date"},Cn=u("$ZodCheckLessThan",(e,t)=>{Y.init(e,t);const n=Sn[typeof t.value];e._zod.onattach.push(i=>{const r=i._zod.bag,s=(t.inclusive?r.maximum:r.exclusiveMaximum)??Number.POSITIVE_INFINITY;t.value<s&&(t.inclusive?r.maximum=t.value:r.exclusiveMaximum=t.value)}),e._zod.check=i=>{(t.inclusive?i.value<=t.value:i.value<t.value)||i.issues.push({origin:n,code:"too_big",maximum:typeof t.value=="object"?t.value.getTime():t.value,input:i.value,inclusive:t.inclusive,inst:e,continue:!t.abort})}}),En=u("$ZodCheckGreaterThan",(e,t)=>{Y.init(e,t);const n=Sn[typeof t.value];e._zod.onattach.push(i=>{const r=i._zod.bag,s=(t.inclusive?r.minimum:r.exclusiveMinimum)??Number.NEGATIVE_INFINITY;t.value>s&&(t.inclusive?r.minimum=t.value:r.exclusiveMinimum=t.value)}),e._zod.check=i=>{(t.inclusive?i.value>=t.value:i.value>t.value)||i.issues.push({origin:n,code:"too_small",minimum:typeof t.value=="object"?t.value.getTime():t.value,input:i.value,inclusive:t.inclusive,inst:e,continue:!t.abort})}}),Po=u("$ZodCheckMultipleOf",(e,t)=>{Y.init(e,t),e._zod.onattach.push(n=>{var i;(i=n._zod.bag).multipleOf??(i.multipleOf=t.value)}),e._zod.check=n=>{if(typeof n.value!=typeof t.value)throw new Error("Cannot mix number and bigint in multiple_of check.");(typeof n.value=="bigint"?n.value%t.value===BigInt(0):Lr(n.value,t.value)===0)||n.issues.push({origin:typeof n.value,code:"not_multiple_of",divisor:t.value,input:n.value,inst:e,continue:!t.abort})}}),Ho=u("$ZodCheckNumberFormat",(e,t)=>{Y.init(e,t),t.format=t.format||"float64";const n=t.format?.includes("int"),i=n?"int":"number",[r,s]=Vr[t.format];e._zod.onattach.push(o=>{const c=o._zod.bag;c.format=t.format,c.minimum=r,c.maximum=s,n&&(c.pattern=To)}),e._zod.check=o=>{const c=o.value;if(n){if(!Number.isInteger(c)){o.issues.push({expected:i,format:t.format,code:"invalid_type",continue:!1,input:c,inst:e});return}if(!Number.isSafeInteger(c)){c>0?o.issues.push({input:c,code:"too_big",maximum:Number.MAX_SAFE_INTEGER,note:"Integers must be within the safe integer range.",inst:e,origin:i,inclusive:!0,continue:!t.abort}):o.issues.push({input:c,code:"too_small",minimum:Number.MIN_SAFE_INTEGER,note:"Integers must be within the safe integer range.",inst:e,origin:i,inclusive:!0,continue:!t.abort});return}}c<r&&o.issues.push({origin:"number",input:c,code:"too_small",minimum:r,inclusive:!0,inst:e,continue:!t.abort}),c>s&&o.issues.push({origin:"number",input:c,code:"too_big",maximum:s,inclusive:!0,inst:e,continue:!t.abort})}}),qo=u("$ZodCheckMaxLength",(e,t)=>{var n;Y.init(e,t),(n=e._zod.def).when??(n.when=i=>{const r=i.value;return!ft(r)&&r.length!==void 0}),e._zod.onattach.push(i=>{const r=i._zod.bag.maximum??Number.POSITIVE_INFINITY;t.maximum<r&&(i._zod.bag.maximum=t.maximum)}),e._zod.check=i=>{const r=i.value;if(r.length<=t.maximum)return;const o=mt(r);i.issues.push({origin:o,code:"too_big",maximum:t.maximum,inclusive:!0,input:r,inst:e,continue:!t.abort})}}),jo=u("$ZodCheckMinLength",(e,t)=>{var n;Y.init(e,t),(n=e._zod.def).when??(n.when=i=>{const r=i.value;return!ft(r)&&r.length!==void 0}),e._zod.onattach.push(i=>{const r=i._zod.bag.minimum??Number.NEGATIVE_INFINITY;t.minimum>r&&(i._zod.bag.minimum=t.minimum)}),e._zod.check=i=>{const r=i.value;if(r.length>=t.minimum)return;const o=mt(r);i.issues.push({origin:o,code:"too_small",minimum:t.minimum,inclusive:!0,input:r,inst:e,continue:!t.abort})}}),Vo=u("$ZodCheckLengthEquals",(e,t)=>{var n;Y.init(e,t),(n=e._zod.def).when??(n.when=i=>{const r=i.value;return!ft(r)&&r.length!==void 0}),e._zod.onattach.push(i=>{const r=i._zod.bag;r.minimum=t.length,r.maximum=t.length,r.length=t.length}),e._zod.check=i=>{const r=i.value,s=r.length;if(s===t.length)return;const o=mt(r),c=s>t.length;i.issues.push({origin:o,...c?{code:"too_big",maximum:t.length}:{code:"too_small",minimum:t.length},inclusive:!0,exact:!0,input:i.value,inst:e,continue:!t.abort})}}),Le=u("$ZodCheckStringFormat",(e,t)=>{var n,i;Y.init(e,t),e._zod.onattach.push(r=>{const s=r._zod.bag;s.format=t.format,t.pattern&&(s.patterns??(s.patterns=new Set),s.patterns.add(t.pattern))}),t.pattern?(n=e._zod).check??(n.check=r=>{t.pattern.lastIndex=0,!t.pattern.test(r.value)&&r.issues.push({origin:"string",code:"invalid_format",format:t.format,input:r.value,...t.pattern?{pattern:t.pattern.toString()}:{},inst:e,continue:!t.abort})}):(i=e._zod).check??(i.check=()=>{})}),Xo=u("$ZodCheckRegex",(e,t)=>{Le.init(e,t),e._zod.check=n=>{t.pattern.lastIndex=0,!t.pattern.test(n.value)&&n.issues.push({origin:"string",code:"invalid_format",format:"regex",input:n.value,pattern:t.pattern.toString(),inst:e,continue:!t.abort})}}),$o=u("$ZodCheckLowerCase",(e,t)=>{t.pattern??(t.pattern=Yo),Le.init(e,t)}),ea=u("$ZodCheckUpperCase",(e,t)=>{t.pattern??(t.pattern=Lo),Le.init(e,t)}),ta=u("$ZodCheckIncludes",(e,t)=>{Y.init(e,t);const n=ke(t.includes),i=new RegExp(typeof t.position=="number"?`^.{${t.position}}${n}`:n);t.pattern=i,e._zod.onattach.push(r=>{const s=r._zod.bag;s.patterns??(s.patterns=new Set),s.patterns.add(i)}),e._zod.check=r=>{r.value.includes(t.includes,t.position)||r.issues.push({origin:"string",code:"invalid_format",format:"includes",includes:t.includes,input:r.value,inst:e,continue:!t.abort})}}),na=u("$ZodCheckStartsWith",(e,t)=>{Y.init(e,t);const n=new RegExp(`^${ke(t.prefix)}.*`);t.pattern??(t.pattern=n),e._zod.onattach.push(i=>{const r=i._zod.bag;r.patterns??(r.patterns=new Set),r.patterns.add(n)}),e._zod.check=i=>{i.value.startsWith(t.prefix)||i.issues.push({origin:"string",code:"invalid_format",format:"starts_with",prefix:t.prefix,input:i.value,inst:e,continue:!t.abort})}}),ia=u("$ZodCheckEndsWith",(e,t)=>{Y.init(e,t);const n=new RegExp(`.*${ke(t.suffix)}$`);t.pattern??(t.pattern=n),e._zod.onattach.push(i=>{const r=i._zod.bag;r.patterns??(r.patterns=new Set),r.patterns.add(n)}),e._zod.check=i=>{i.value.endsWith(t.suffix)||i.issues.push({origin:"string",code:"invalid_format",format:"ends_with",suffix:t.suffix,input:i.value,inst:e,continue:!t.abort})}}),ra=u("$ZodCheckOverwrite",(e,t)=>{Y.init(e,t),e._zod.check=n=>{n.value=t.tx(n.value)}});class oa{constructor(t=[]){this.content=[],this.indent=0,this&&(this.args=t)}indented(t){this.indent+=1,t(this),this.indent-=1}write(t){if(typeof t=="function"){t(this,{execution:"sync"}),t(this,{execution:"async"});return}const i=t.split(`
`).filter(o=>o),r=Math.min(...i.map(o=>o.length-o.trimStart().length)),s=i.map(o=>o.slice(r)).map(o=>" ".repeat(this.indent*2)+o);for(const o of s)this.content.push(o)}compile(){const t=Function,n=this?.args,r=[...(this?.content??[""]).map(s=>`  ${s}`)];return new t(...n,r.join(`
`))}}const aa={major:4,minor:4,patch:3},D=u("$ZodType",(e,t)=>{var n;e??(e={}),e._zod.def=t,e._zod.bag=e._zod.bag||{},e._zod.version=aa;const i=[...e._zod.def.checks??[]];e._zod.traits.has("$ZodCheck")&&i.unshift(e);for(const r of i)for(const s of r._zod.onattach)s(e);if(i.length===0)(n=e._zod).deferred??(n.deferred=[]),e._zod.deferred?.push(()=>{e._zod.run=e._zod.parse});else{const r=(o,c,l)=>{let A=Ie(o),m;for(const y of c){if(y._zod.def.when){if(oo(o)||!y._zod.def.when(o))continue}else if(A)continue;const I=o.issues.length,v=y._zod.check(o);if(v instanceof Promise&&l?.async===!1)throw new ye;if(m||v instanceof Promise)m=(m??Promise.resolve()).then(async()=>{await v,o.issues.length!==I&&(A||(A=Ie(o,I)))});else{if(o.issues.length===I)continue;A||(A=Ie(o,I))}}return m?m.then(()=>o):o},s=(o,c,l)=>{if(Ie(o))return o.aborted=!0,o;const A=r(c,i,l);if(A instanceof Promise){if(l.async===!1)throw new ye;return A.then(m=>e._zod.parse(m,l))}return e._zod.parse(A,l)};e._zod.run=(o,c)=>{if(c.skipChecks)return e._zod.parse(o,c);if(c.direction==="backward"){const A=e._zod.parse({value:o.value,issues:[]},{...c,skipChecks:!0});return A instanceof Promise?A.then(m=>s(m,o,c)):s(A,o,c)}const l=e._zod.parse(o,c);if(l instanceof Promise){if(c.async===!1)throw new ye;return l.then(A=>r(A,i,c))}return r(l,i,c)}}E(e,"~standard",()=>({validate:r=>{try{const s=co(e,r);return s.success?{value:s.data}:{issues:s.error?.issues}}catch{return lo(e,r).then(o=>o.success?{value:o.data}:{issues:o.error?.issues})}},vendor:"zod",version:1}))}),bt=u("$ZodString",(e,t)=>{D.init(e,t),e._zod.pattern=[...e?._zod.bag?.patterns??[]].pop()??Ko(e._zod.bag),e._zod.parse=(n,i)=>{if(t.coerce)try{n.value=String(n.value)}catch{}return typeof n.value=="string"||n.issues.push({expected:"string",code:"invalid_type",input:n.value,inst:e}),n}}),F=u("$ZodStringFormat",(e,t)=>{Le.init(e,t),bt.init(e,t)}),sa=u("$ZodGUID",(e,t)=>{t.pattern??(t.pattern=Co),F.init(e,t)}),ca=u("$ZodUUID",(e,t)=>{if(t.version){const i={v1:1,v2:2,v3:3,v4:4,v5:5,v6:6,v7:7,v8:8}[t.version];if(i===void 0)throw new Error(`Invalid UUID version: "${t.version}"`);t.pattern??(t.pattern=yn(i))}else t.pattern??(t.pattern=yn());F.init(e,t)}),la=u("$ZodEmail",(e,t)=>{t.pattern??(t.pattern=Eo),F.init(e,t)}),Aa=u("$ZodURL",(e,t)=>{F.init(e,t),e._zod.check=n=>{try{const i=n.value.trim();if(!t.normalize&&t.protocol?.source===Qo.source&&!/^https?:\/\//i.test(i)){n.issues.push({code:"invalid_format",format:"url",note:"Invalid URL format",input:n.value,inst:e,continue:!t.abort});return}const r=new URL(i);t.hostname&&(t.hostname.lastIndex=0,t.hostname.test(r.hostname)||n.issues.push({code:"invalid_format",format:"url",note:"Invalid hostname",pattern:t.hostname.source,input:n.value,inst:e,continue:!t.abort})),t.protocol&&(t.protocol.lastIndex=0,t.protocol.test(r.protocol.endsWith(":")?r.protocol.slice(0,-1):r.protocol)||n.issues.push({code:"invalid_format",format:"url",note:"Invalid protocol",pattern:t.protocol.source,input:n.value,inst:e,continue:!t.abort})),t.normalize?n.value=r.href:n.value=i;return}catch{n.issues.push({code:"invalid_format",format:"url",input:n.value,inst:e,continue:!t.abort})}}}),ua=u("$ZodEmoji",(e,t)=>{t.pattern??(t.pattern=_o()),F.init(e,t)}),da=u("$ZodNanoID",(e,t)=>{t.pattern??(t.pattern=xo),F.init(e,t)}),ha=u("$ZodCUID",(e,t)=>{t.pattern??(t.pattern=bo),F.init(e,t)}),fa=u("$ZodCUID2",(e,t)=>{t.pattern??(t.pattern=yo),F.init(e,t)}),pa=u("$ZodULID",(e,t)=>{t.pattern??(t.pattern=vo),F.init(e,t)}),ma=u("$ZodXID",(e,t)=>{t.pattern??(t.pattern=ko),F.init(e,t)}),ga=u("$ZodKSUID",(e,t)=>{t.pattern??(t.pattern=Io),F.init(e,t)}),wa=u("$ZodISODateTime",(e,t)=>{t.pattern??(t.pattern=zo(t)),F.init(e,t)}),ba=u("$ZodISODate",(e,t)=>{t.pattern??(t.pattern=Uo),F.init(e,t)}),ya=u("$ZodISOTime",(e,t)=>{t.pattern??(t.pattern=Wo(t)),F.init(e,t)}),va=u("$ZodISODuration",(e,t)=>{t.pattern??(t.pattern=So),F.init(e,t)}),ka=u("$ZodIPv4",(e,t)=>{t.pattern??(t.pattern=Do),F.init(e,t),e._zod.bag.format="ipv4"}),Ia=u("$ZodIPv6",(e,t)=>{t.pattern??(t.pattern=No),F.init(e,t),e._zod.bag.format="ipv6",e._zod.check=n=>{try{new URL(`http://[${n.value}]`)}catch{n.issues.push({code:"invalid_format",format:"ipv6",input:n.value,inst:e,continue:!t.abort})}}}),xa=u("$ZodCIDRv4",(e,t)=>{t.pattern??(t.pattern=Fo),F.init(e,t)}),Sa=u("$ZodCIDRv6",(e,t)=>{t.pattern??(t.pattern=Zo),F.init(e,t),e._zod.check=n=>{const i=n.value.split("/");try{if(i.length!==2)throw new Error;const[r,s]=i;if(!s)throw new Error;const o=Number(s);if(`${o}`!==s)throw new Error;if(o<0||o>128)throw new Error;new URL(`http://[${r}]`)}catch{n.issues.push({code:"invalid_format",format:"cidrv6",input:n.value,inst:e,continue:!t.abort})}}});function Bn(e){if(e==="")return!0;if(/\s/.test(e)||e.length%4!==0)return!1;try{return atob(e),!0}catch{return!1}}const Ca=u("$ZodBase64",(e,t)=>{t.pattern??(t.pattern=Ro),F.init(e,t),e._zod.bag.contentEncoding="base64",e._zod.check=n=>{Bn(n.value)||n.issues.push({code:"invalid_format",format:"base64",input:n.value,inst:e,continue:!t.abort})}});function Ea(e){if(!vn.test(e))return!1;const t=e.replace(/[-_]/g,i=>i==="-"?"+":"/"),n=t.padEnd(Math.ceil(t.length/4)*4,"=");return Bn(n)}const Ba=u("$ZodBase64URL",(e,t)=>{t.pattern??(t.pattern=vn),F.init(e,t),e._zod.bag.contentEncoding="base64url",e._zod.check=n=>{Ea(n.value)||n.issues.push({code:"invalid_format",format:"base64url",input:n.value,inst:e,continue:!t.abort})}}),_a=u("$ZodE164",(e,t)=>{t.pattern??(t.pattern=Oo),F.init(e,t)});function Da(e,t=null){try{const n=e.split(".");if(n.length!==3)return!1;const[i]=n;if(!i)return!1;const r=JSON.parse(atob(i));return!("typ"in r&&r?.typ!=="JWT"||!r.alg||t&&(!("alg"in r)||r.alg!==t))}catch{return!1}}const Na=u("$ZodJWT",(e,t)=>{F.init(e,t),e._zod.check=n=>{Da(n.value,t.alg)||n.issues.push({code:"invalid_format",format:"jwt",input:n.value,inst:e,continue:!t.abort})}}),_n=u("$ZodNumber",(e,t)=>{D.init(e,t),e._zod.pattern=e._zod.bag.pattern??xn,e._zod.parse=(n,i)=>{if(t.coerce)try{n.value=Number(n.value)}catch{}const r=n.value;if(typeof r=="number"&&!Number.isNaN(r)&&Number.isFinite(r))return n;const s=typeof r=="number"?Number.isNaN(r)?"NaN":Number.isFinite(r)?void 0:"Infinity":void 0;return n.issues.push({expected:"number",code:"invalid_type",input:r,inst:e,...s?{received:s}:{}}),n}}),Fa=u("$ZodNumberFormat",(e,t)=>{Ho.init(e,t),_n.init(e,t)}),Za=u("$ZodBoolean",(e,t)=>{D.init(e,t),e._zod.pattern=Go,e._zod.parse=(n,i)=>{if(t.coerce)try{n.value=!!n.value}catch{}const r=n.value;return typeof r=="boolean"||n.issues.push({expected:"boolean",code:"invalid_type",input:r,inst:e}),n}}),Ra=u("$ZodUndefined",(e,t)=>{D.init(e,t),e._zod.pattern=Jo,e._zod.values=new Set([void 0]),e._zod.parse=(n,i)=>{const r=n.value;return typeof r>"u"||n.issues.push({expected:"undefined",code:"invalid_type",input:r,inst:e}),n}}),Qa=u("$ZodNull",(e,t)=>{D.init(e,t),e._zod.pattern=Mo,e._zod.values=new Set([null]),e._zod.parse=(n,i)=>{const r=n.value;return r===null||n.issues.push({expected:"null",code:"invalid_type",input:r,inst:e}),n}}),Oa=u("$ZodUnknown",(e,t)=>{D.init(e,t),e._zod.parse=n=>n}),Ua=u("$ZodNever",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>(n.issues.push({expected:"never",code:"invalid_type",input:n.value,inst:e}),n)});function Dn(e,t,n){e.issues.length&&t.issues.push(...xe(n,e.issues)),t.value[n]=e.value}const Wa=u("$ZodArray",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>{const r=n.value;if(!Array.isArray(r))return n.issues.push({expected:"array",code:"invalid_type",input:r,inst:e}),n;n.value=Array(r.length);const s=[];for(let o=0;o<r.length;o++){const c=r[o],l=t.element._zod.run({value:c,issues:[]},i);l instanceof Promise?s.push(l.then(A=>Dn(A,n,o))):Dn(l,n,o)}return s.length?Promise.all(s).then(()=>n):n}});function Pe(e,t,n,i,r,s){const o=n in i;if(e.issues.length){if(r&&s&&!o)return;t.issues.push(...xe(n,e.issues))}if(!o&&!r){e.issues.length||t.issues.push({code:"invalid_type",expected:"nonoptional",input:void 0,path:[n]});return}e.value===void 0?o&&(t.value[n]=void 0):t.value[n]=e.value}function Nn(e){const t=Object.keys(e.shape);for(const i of t)if(!e.shape?.[i]?._zod?.traits?.has("$ZodType"))throw new Error(`Invalid element at key "${i}": expected a Zod schema`);const n=jr(e.shape);return{...e,keys:t,keySet:new Set(t),numKeys:t.length,optionalKeys:new Set(n)}}function Fn(e,t,n,i,r,s){const o=[],c=r.keySet,l=r.catchall._zod,A=l.def.type,m=l.optin==="optional",y=l.optout==="optional";for(const I in t){if(I==="__proto__"||c.has(I))continue;if(A==="never"){o.push(I);continue}const v=l.run({value:t[I],issues:[]},i);v instanceof Promise?e.push(v.then(B=>Pe(B,n,I,t,m,y))):Pe(v,n,I,t,m,y)}return o.length&&n.issues.push({code:"unrecognized_keys",keys:o,input:t,inst:s}),e.length?Promise.all(e).then(()=>n):n}const za=u("$ZodObject",(e,t)=>{if(D.init(e,t),!Object.getOwnPropertyDescriptor(t,"shape")?.get){const c=t.shape;Object.defineProperty(t,"shape",{get:()=>{const l={...c};return Object.defineProperty(t,"shape",{value:l}),l}})}const i=Ge(()=>Nn(t));E(e._zod,"propValues",()=>{const c=t.shape,l={};for(const A in c){const m=c[A]._zod;if(m.values){l[A]??(l[A]=new Set);for(const y of m.values)l[A].add(y)}}return l});const r=Re,s=t.catchall;let o;e._zod.parse=(c,l)=>{o??(o=i.value);const A=c.value;if(!r(A))return c.issues.push({expected:"object",code:"invalid_type",input:A,inst:e}),c;c.value={};const m=[],y=o.shape;for(const I of o.keys){const v=y[I],B=v._zod.optin==="optional",be=v._zod.optout==="optional",K=v._zod.run({value:A[I],issues:[]},l);K instanceof Promise?m.push(K.then(ln=>Pe(ln,c,I,A,B,be))):Pe(K,c,I,A,B,be)}return s?Fn(m,A,c,l,i.value,e):m.length?Promise.all(m).then(()=>c):c}}),Ka=u("$ZodObjectJIT",(e,t)=>{za.init(e,t);const n=e._zod.parse,i=Ge(()=>Nn(t)),r=I=>{const v=new oa(["shape","payload","ctx"]),B=i.value,be=te=>{const U=fn(te);return`shape[${U}]._zod.run({ value: input[${U}], issues: [] }, ctx)`};v.write("const input = payload.value;");const K=Object.create(null);let ln=0;for(const te of B.keys)K[te]=`key_${ln++}`;v.write("const newResult = {};");for(const te of B.keys){const U=K[te],T=fn(te),Jr=I[te],Yr=Jr?._zod?.optin==="optional",mh=Jr?._zod?.optout==="optional";v.write(`const ${U} = ${be(te)};`),Yr&&mh?v.write(`
        if (${U}.issues.length) {
          if (${T} in input) {
            payload.issues = payload.issues.concat(${U}.issues.map(iss => ({
              ...iss,
              path: iss.path ? [${T}, ...iss.path] : [${T}]
            })));
          }
        }
        
        if (${U}.value === undefined) {
          if (${T} in input) {
            newResult[${T}] = undefined;
          }
        } else {
          newResult[${T}] = ${U}.value;
        }
        
      `):Yr?v.write(`
        if (${U}.issues.length) {
          payload.issues = payload.issues.concat(${U}.issues.map(iss => ({
            ...iss,
            path: iss.path ? [${T}, ...iss.path] : [${T}]
          })));
        }
        
        if (${U}.value === undefined) {
          if (${T} in input) {
            newResult[${T}] = undefined;
          }
        } else {
          newResult[${T}] = ${U}.value;
        }
        
      `):v.write(`
        const ${U}_present = ${T} in input;
        if (${U}.issues.length) {
          payload.issues = payload.issues.concat(${U}.issues.map(iss => ({
            ...iss,
            path: iss.path ? [${T}, ...iss.path] : [${T}]
          })));
        }
        if (!${U}_present && !${U}.issues.length) {
          payload.issues.push({
            code: "invalid_type",
            expected: "nonoptional",
            input: undefined,
            path: [${T}]
          });
        }

        if (${U}_present) {
          if (${U}.value === undefined) {
            newResult[${T}] = undefined;
          } else {
            newResult[${T}] = ${U}.value;
          }
        }

      `)}v.write("payload.value = newResult;"),v.write("return payload;");const ph=v.compile();return(te,U)=>ph(I,te,U)};let s;const o=Re,c=!dt.jitless,A=c&&Hr.value,m=t.catchall;let y;e._zod.parse=(I,v)=>{y??(y=i.value);const B=I.value;return o(B)?c&&A&&v?.async===!1&&v.jitless!==!0?(s||(s=r(t.shape)),I=s(I,v),m?Fn([],B,I,v,y,e):I):n(I,v):(I.issues.push({expected:"object",code:"invalid_type",input:B,inst:e}),I)}});function Zn(e,t,n,i){for(const s of e)if(s.issues.length===0)return t.value=s.value,t;const r=e.filter(s=>!Ie(s));return r.length===1?(t.value=r[0].value,r[0]):(t.issues.push({code:"invalid_union",input:t.value,inst:n,errors:e.map(s=>s.issues.map(o=>ie(o,i,ne())))}),t)}const Rn=u("$ZodUnion",(e,t)=>{D.init(e,t),E(e._zod,"optin",()=>t.options.some(i=>i._zod.optin==="optional")?"optional":void 0),E(e._zod,"optout",()=>t.options.some(i=>i._zod.optout==="optional")?"optional":void 0),E(e._zod,"values",()=>{if(t.options.every(i=>i._zod.values))return new Set(t.options.flatMap(i=>Array.from(i._zod.values)))}),E(e._zod,"pattern",()=>{if(t.options.every(i=>i._zod.pattern)){const i=t.options.map(r=>r._zod.pattern);return new RegExp(`^(${i.map(r=>pt(r.source)).join("|")})$`)}});const n=t.options.length===1?t.options[0]._zod.run:null;e._zod.parse=(i,r)=>{if(n)return n(i,r);let s=!1;const o=[];for(const c of t.options){const l=c._zod.run({value:i.value,issues:[]},r);if(l instanceof Promise)o.push(l),s=!0;else{if(l.issues.length===0)return l;o.push(l)}}return s?Promise.all(o).then(c=>Zn(c,i,e,r)):Zn(o,i,e,r)}}),Ta=u("$ZodDiscriminatedUnion",(e,t)=>{t.inclusive=!1,Rn.init(e,t);const n=e._zod.parse;E(e._zod,"propValues",()=>{const r={};for(const s of t.options){const o=s._zod.propValues;if(!o||Object.keys(o).length===0)throw new Error(`Invalid discriminated union option at index "${t.options.indexOf(s)}"`);for(const[c,l]of Object.entries(o)){r[c]||(r[c]=new Set);for(const A of l)r[c].add(A)}}return r});const i=Ge(()=>{const r=t.options,s=new Map;for(const o of r){const c=o._zod.propValues?.[t.discriminator];if(!c||c.size===0)throw new Error(`Invalid discriminated union option at index "${t.options.indexOf(o)}"`);for(const l of c){if(s.has(l))throw new Error(`Duplicate discriminator value "${String(l)}"`);s.set(l,o)}}return s});e._zod.parse=(r,s)=>{const o=r.value;if(!Re(o))return r.issues.push({code:"invalid_type",expected:"object",input:o,inst:e}),r;const c=i.value.get(o?.[t.discriminator]);return c?c._zod.run(r,s):t.unionFallback||s.direction==="backward"?n(r,s):(r.issues.push({code:"invalid_union",errors:[],note:"No matching discriminator",discriminator:t.discriminator,options:Array.from(i.value.keys()),input:o,path:[t.discriminator],inst:e}),r)}}),Ga=u("$ZodIntersection",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>{const r=n.value,s=t.left._zod.run({value:r,issues:[]},i),o=t.right._zod.run({value:r,issues:[]},i);return s instanceof Promise||o instanceof Promise?Promise.all([s,o]).then(([l,A])=>Qn(n,l,A)):Qn(n,s,o)}});function yt(e,t){if(e===t)return{valid:!0,data:e};if(e instanceof Date&&t instanceof Date&&+e==+t)return{valid:!0,data:e};if(ve(e)&&ve(t)){const n=Object.keys(t),i=Object.keys(e).filter(s=>n.indexOf(s)!==-1),r={...e,...t};for(const s of i){const o=yt(e[s],t[s]);if(!o.valid)return{valid:!1,mergeErrorPath:[s,...o.mergeErrorPath]};r[s]=o.data}return{valid:!0,data:r}}if(Array.isArray(e)&&Array.isArray(t)){if(e.length!==t.length)return{valid:!1,mergeErrorPath:[]};const n=[];for(let i=0;i<e.length;i++){const r=e[i],s=t[i],o=yt(r,s);if(!o.valid)return{valid:!1,mergeErrorPath:[i,...o.mergeErrorPath]};n.push(o.data)}return{valid:!0,data:n}}return{valid:!1,mergeErrorPath:[]}}function Qn(e,t,n){const i=new Map;let r;for(const c of t.issues)if(c.code==="unrecognized_keys"){r??(r=c);for(const l of c.keys)i.has(l)||i.set(l,{}),i.get(l).l=!0}else e.issues.push(c);for(const c of n.issues)if(c.code==="unrecognized_keys")for(const l of c.keys)i.has(l)||i.set(l,{}),i.get(l).r=!0;else e.issues.push(c);const s=[...i].filter(([,c])=>c.l&&c.r).map(([c])=>c);if(s.length&&r&&e.issues.push({...r,keys:s}),Ie(e))return e;const o=yt(t.value,n.value);if(!o.valid)throw new Error(`Unmergable intersection. Error path: ${JSON.stringify(o.mergeErrorPath)}`);return e.value=o.data,e}const Ma=u("$ZodRecord",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>{const r=n.value;if(!ve(r))return n.issues.push({expected:"record",code:"invalid_type",input:r,inst:e}),n;const s=[],o=t.keyType._zod.values;if(o){n.value={};const c=new Set;for(const A of o)if(typeof A=="string"||typeof A=="number"||typeof A=="symbol"){c.add(typeof A=="number"?A.toString():A);const m=t.keyType._zod.run({value:A,issues:[]},i);if(m instanceof Promise)throw new Error("Async schemas not supported in object keys currently");if(m.issues.length){n.issues.push({code:"invalid_key",origin:"record",issues:m.issues.map(v=>ie(v,i,ne())),input:A,path:[A],inst:e});continue}const y=m.value,I=t.valueType._zod.run({value:r[A],issues:[]},i);I instanceof Promise?s.push(I.then(v=>{v.issues.length&&n.issues.push(...xe(A,v.issues)),n.value[y]=v.value})):(I.issues.length&&n.issues.push(...xe(A,I.issues)),n.value[y]=I.value)}let l;for(const A in r)c.has(A)||(l=l??[],l.push(A));l&&l.length>0&&n.issues.push({code:"unrecognized_keys",input:r,inst:e,keys:l})}else{n.value={};for(const c of Reflect.ownKeys(r)){if(c==="__proto__"||!Object.prototype.propertyIsEnumerable.call(r,c))continue;let l=t.keyType._zod.run({value:c,issues:[]},i);if(l instanceof Promise)throw new Error("Async schemas not supported in object keys currently");if(typeof c=="string"&&xn.test(c)&&l.issues.length){const y=t.keyType._zod.run({value:Number(c),issues:[]},i);if(y instanceof Promise)throw new Error("Async schemas not supported in object keys currently");y.issues.length===0&&(l=y)}if(l.issues.length){t.mode==="loose"?n.value[c]=r[c]:n.issues.push({code:"invalid_key",origin:"record",issues:l.issues.map(y=>ie(y,i,ne())),input:c,path:[c],inst:e});continue}const m=t.valueType._zod.run({value:r[c],issues:[]},i);m instanceof Promise?s.push(m.then(y=>{y.issues.length&&n.issues.push(...xe(c,y.issues)),n.value[l.value]=y.value})):(m.issues.length&&n.issues.push(...xe(c,m.issues)),n.value[l.value]=m.value)}}return s.length?Promise.all(s).then(()=>n):n}}),Ja=u("$ZodEnum",(e,t)=>{D.init(e,t);const n=dn(t.entries),i=new Set(n);e._zod.values=i,e._zod.pattern=new RegExp(`^(${n.filter(r=>qr.has(typeof r)).map(r=>typeof r=="string"?ke(r):r.toString()).join("|")})$`),e._zod.parse=(r,s)=>{const o=r.value;return i.has(o)||r.issues.push({code:"invalid_value",values:n,input:o,inst:e}),r}}),Ya=u("$ZodLiteral",(e,t)=>{if(D.init(e,t),t.values.length===0)throw new Error("Cannot create literal schema with no valid values");const n=new Set(t.values);e._zod.values=n,e._zod.pattern=new RegExp(`^(${t.values.map(i=>typeof i=="string"?ke(i):i?ke(i.toString()):String(i)).join("|")})$`),e._zod.parse=(i,r)=>{const s=i.value;return n.has(s)||i.issues.push({code:"invalid_value",values:t.values,input:s,inst:e}),i}}),La=u("$ZodTransform",(e,t)=>{D.init(e,t),e._zod.optin="optional",e._zod.parse=(n,i)=>{if(i.direction==="backward")throw new un(e.constructor.name);const r=t.transform(n.value,n);if(i.async)return(r instanceof Promise?r:Promise.resolve(r)).then(o=>(n.value=o,n.fallback=!0,n));if(r instanceof Promise)throw new ye;return n.value=r,n.fallback=!0,n}});function On(e,t){return t===void 0&&(e.issues.length||e.fallback)?{issues:[],value:void 0}:e}const Un=u("$ZodOptional",(e,t)=>{D.init(e,t),e._zod.optin="optional",e._zod.optout="optional",E(e._zod,"values",()=>t.innerType._zod.values?new Set([...t.innerType._zod.values,void 0]):void 0),E(e._zod,"pattern",()=>{const n=t.innerType._zod.pattern;return n?new RegExp(`^(${pt(n.source)})?$`):void 0}),e._zod.parse=(n,i)=>{if(t.innerType._zod.optin==="optional"){const r=n.value,s=t.innerType._zod.run(n,i);return s instanceof Promise?s.then(o=>On(o,r)):On(s,r)}return n.value===void 0?n:t.innerType._zod.run(n,i)}}),Pa=u("$ZodExactOptional",(e,t)=>{Un.init(e,t),E(e._zod,"values",()=>t.innerType._zod.values),E(e._zod,"pattern",()=>t.innerType._zod.pattern),e._zod.parse=(n,i)=>t.innerType._zod.run(n,i)}),Ha=u("$ZodNullable",(e,t)=>{D.init(e,t),E(e._zod,"optin",()=>t.innerType._zod.optin),E(e._zod,"optout",()=>t.innerType._zod.optout),E(e._zod,"pattern",()=>{const n=t.innerType._zod.pattern;return n?new RegExp(`^(${pt(n.source)}|null)$`):void 0}),E(e._zod,"values",()=>t.innerType._zod.values?new Set([...t.innerType._zod.values,null]):void 0),e._zod.parse=(n,i)=>n.value===null?n:t.innerType._zod.run(n,i)}),qa=u("$ZodDefault",(e,t)=>{D.init(e,t),e._zod.optin="optional",E(e._zod,"values",()=>t.innerType._zod.values),e._zod.parse=(n,i)=>{if(i.direction==="backward")return t.innerType._zod.run(n,i);if(n.value===void 0)return n.value=t.defaultValue,n;const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(s=>Wn(s,t)):Wn(r,t)}});function Wn(e,t){return e.value===void 0&&(e.value=t.defaultValue),e}const ja=u("$ZodPrefault",(e,t)=>{D.init(e,t),e._zod.optin="optional",E(e._zod,"values",()=>t.innerType._zod.values),e._zod.parse=(n,i)=>(i.direction==="backward"||n.value===void 0&&(n.value=t.defaultValue),t.innerType._zod.run(n,i))}),Va=u("$ZodNonOptional",(e,t)=>{D.init(e,t),E(e._zod,"values",()=>{const n=t.innerType._zod.values;return n?new Set([...n].filter(i=>i!==void 0)):void 0}),e._zod.parse=(n,i)=>{const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(s=>zn(s,e)):zn(r,e)}});function zn(e,t){return!e.issues.length&&e.value===void 0&&e.issues.push({code:"invalid_type",expected:"nonoptional",input:e.value,inst:t}),e}const Xa=u("$ZodCatch",(e,t)=>{D.init(e,t),e._zod.optin="optional",E(e._zod,"optout",()=>t.innerType._zod.optout),E(e._zod,"values",()=>t.innerType._zod.values),e._zod.parse=(n,i)=>{if(i.direction==="backward")return t.innerType._zod.run(n,i);const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(s=>(n.value=s.value,s.issues.length&&(n.value=t.catchValue({...n,error:{issues:s.issues.map(o=>ie(o,i,ne()))},input:n.value}),n.issues=[],n.fallback=!0),n)):(n.value=r.value,r.issues.length&&(n.value=t.catchValue({...n,error:{issues:r.issues.map(s=>ie(s,i,ne()))},input:n.value}),n.issues=[],n.fallback=!0),n)}}),$a=u("$ZodPipe",(e,t)=>{D.init(e,t),E(e._zod,"values",()=>t.in._zod.values),E(e._zod,"optin",()=>t.in._zod.optin),E(e._zod,"optout",()=>t.out._zod.optout),E(e._zod,"propValues",()=>t.in._zod.propValues),e._zod.parse=(n,i)=>{if(i.direction==="backward"){const s=t.out._zod.run(n,i);return s instanceof Promise?s.then(o=>He(o,t.in,i)):He(s,t.in,i)}const r=t.in._zod.run(n,i);return r instanceof Promise?r.then(s=>He(s,t.out,i)):He(r,t.out,i)}});function He(e,t,n){return e.issues.length?(e.aborted=!0,e):t._zod.run({value:e.value,issues:e.issues,fallback:e.fallback},n)}const es=u("$ZodReadonly",(e,t)=>{D.init(e,t),E(e._zod,"propValues",()=>t.innerType._zod.propValues),E(e._zod,"values",()=>t.innerType._zod.values),E(e._zod,"optin",()=>t.innerType?._zod?.optin),E(e._zod,"optout",()=>t.innerType?._zod?.optout),e._zod.parse=(n,i)=>{if(i.direction==="backward")return t.innerType._zod.run(n,i);const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(Kn):Kn(r)}});function Kn(e){return e.value=Object.freeze(e.value),e}const ts=u("$ZodLazy",(e,t)=>{D.init(e,t),E(e._zod,"innerType",()=>{const n=t;return n._cachedInner||(n._cachedInner=t.getter()),n._cachedInner}),E(e._zod,"pattern",()=>e._zod.innerType?._zod?.pattern),E(e._zod,"propValues",()=>e._zod.innerType?._zod?.propValues),E(e._zod,"optin",()=>e._zod.innerType?._zod?.optin??void 0),E(e._zod,"optout",()=>e._zod.innerType?._zod?.optout??void 0),e._zod.parse=(n,i)=>e._zod.innerType._zod.run(n,i)}),ns=u("$ZodCustom",(e,t)=>{Y.init(e,t),D.init(e,t),e._zod.parse=(n,i)=>n,e._zod.check=n=>{const i=n.value,r=t.fn(i);if(r instanceof Promise)return r.then(s=>Tn(s,n,i,e));Tn(r,n,i,e)}});function Tn(e,t,n,i){if(!e){const r={code:"custom",input:n,inst:i,path:[...i._zod.def.path??[]],continue:!i._zod.def.abort};i._zod.def.params&&(r.params=i._zod.def.params),t.issues.push(Qe(r))}}var Gn;class is{constructor(){this._map=new WeakMap,this._idmap=new Map}add(t,...n){const i=n[0];return this._map.set(t,i),i&&typeof i=="object"&&"id"in i&&this._idmap.set(i.id,t),this}clear(){return this._map=new WeakMap,this._idmap=new Map,this}remove(t){const n=this._map.get(t);return n&&typeof n=="object"&&"id"in n&&this._idmap.delete(n.id),this._map.delete(t),this}get(t){const n=t._zod.parent;if(n){const i={...this.get(n)??{}};delete i.id;const r={...i,...this._map.get(t)};return Object.keys(r).length?r:void 0}return this._map.get(t)}has(t){return this._map.has(t)}}function rs(){return new is}(Gn=globalThis).__zod_globalRegistry??(Gn.__zod_globalRegistry=rs());const Oe=globalThis.__zod_globalRegistry;function os(e,t){return new e({type:"string",...k(t)})}function as(e,t){return new e({type:"string",format:"email",check:"string_format",abort:!1,...k(t)})}function Mn(e,t){return new e({type:"string",format:"guid",check:"string_format",abort:!1,...k(t)})}function ss(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,...k(t)})}function cs(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,version:"v4",...k(t)})}function ls(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,version:"v6",...k(t)})}function As(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,version:"v7",...k(t)})}function us(e,t){return new e({type:"string",format:"url",check:"string_format",abort:!1,...k(t)})}function ds(e,t){return new e({type:"string",format:"emoji",check:"string_format",abort:!1,...k(t)})}function hs(e,t){return new e({type:"string",format:"nanoid",check:"string_format",abort:!1,...k(t)})}function fs(e,t){return new e({type:"string",format:"cuid",check:"string_format",abort:!1,...k(t)})}function ps(e,t){return new e({type:"string",format:"cuid2",check:"string_format",abort:!1,...k(t)})}function ms(e,t){return new e({type:"string",format:"ulid",check:"string_format",abort:!1,...k(t)})}function gs(e,t){return new e({type:"string",format:"xid",check:"string_format",abort:!1,...k(t)})}function ws(e,t){return new e({type:"string",format:"ksuid",check:"string_format",abort:!1,...k(t)})}function bs(e,t){return new e({type:"string",format:"ipv4",check:"string_format",abort:!1,...k(t)})}function ys(e,t){return new e({type:"string",format:"ipv6",check:"string_format",abort:!1,...k(t)})}function vs(e,t){return new e({type:"string",format:"cidrv4",check:"string_format",abort:!1,...k(t)})}function ks(e,t){return new e({type:"string",format:"cidrv6",check:"string_format",abort:!1,...k(t)})}function Is(e,t){return new e({type:"string",format:"base64",check:"string_format",abort:!1,...k(t)})}function xs(e,t){return new e({type:"string",format:"base64url",check:"string_format",abort:!1,...k(t)})}function Ss(e,t){return new e({type:"string",format:"e164",check:"string_format",abort:!1,...k(t)})}function Cs(e,t){return new e({type:"string",format:"jwt",check:"string_format",abort:!1,...k(t)})}function Es(e,t){return new e({type:"string",format:"datetime",check:"string_format",offset:!1,local:!1,precision:null,...k(t)})}function Bs(e,t){return new e({type:"string",format:"date",check:"string_format",...k(t)})}function _s(e,t){return new e({type:"string",format:"time",check:"string_format",precision:null,...k(t)})}function Ds(e,t){return new e({type:"string",format:"duration",check:"string_format",...k(t)})}function Ns(e,t){return new e({type:"number",checks:[],...k(t)})}function Fs(e,t){return new e({type:"number",check:"number_format",abort:!1,format:"safeint",...k(t)})}function Zs(e,t){return new e({type:"boolean",...k(t)})}function Rs(e,t){return new e({type:"undefined",...k(t)})}function Qs(e,t){return new e({type:"null",...k(t)})}function Os(e){return new e({type:"unknown"})}function Us(e,t){return new e({type:"never",...k(t)})}function Jn(e,t){return new Cn({check:"less_than",...k(t),value:e,inclusive:!1})}function vt(e,t){return new Cn({check:"less_than",...k(t),value:e,inclusive:!0})}function Yn(e,t){return new En({check:"greater_than",...k(t),value:e,inclusive:!1})}function kt(e,t){return new En({check:"greater_than",...k(t),value:e,inclusive:!0})}function Ln(e,t){return new Po({check:"multiple_of",...k(t),value:e})}function Pn(e,t){return new qo({check:"max_length",...k(t),maximum:e})}function qe(e,t){return new jo({check:"min_length",...k(t),minimum:e})}function Hn(e,t){return new Vo({check:"length_equals",...k(t),length:e})}function Ws(e,t){return new Xo({check:"string_format",format:"regex",...k(t),pattern:e})}function zs(e){return new $o({check:"string_format",format:"lowercase",...k(e)})}function Ks(e){return new ea({check:"string_format",format:"uppercase",...k(e)})}function Ts(e,t){return new ta({check:"string_format",format:"includes",...k(t),includes:e})}function Gs(e,t){return new na({check:"string_format",format:"starts_with",...k(t),prefix:e})}function Ms(e,t){return new ia({check:"string_format",format:"ends_with",...k(t),suffix:e})}function Se(e){return new ra({check:"overwrite",tx:e})}function Js(e){return Se(t=>t.normalize(e))}function Ys(){return Se(e=>e.trim())}function Ls(){return Se(e=>e.toLowerCase())}function Ps(){return Se(e=>e.toUpperCase())}function Hs(){return Se(e=>Pr(e))}function qs(e,t,n){return new e({type:"array",element:t,...k(n)})}function js(e,t,n){return new e({type:"custom",check:"custom",fn:t,...k(n)})}function Vs(e,t){const n=Xs(i=>(i.addIssue=r=>{if(typeof r=="string")i.issues.push(Qe(r,i.value,n._zod.def));else{const s=r;s.fatal&&(s.continue=!1),s.code??(s.code="custom"),s.input??(s.input=i.value),s.inst??(s.inst=n),s.continue??(s.continue=!n._zod.def.abort),i.issues.push(Qe(s))}},e(i.value,i)),t);return n}function Xs(e,t){const n=new Y({check:"custom",...k(t)});return n._zod.check=e,n}function qn(e){let t=e?.target??"draft-2020-12";return t==="draft-4"&&(t="draft-04"),t==="draft-7"&&(t="draft-07"),{processors:e.processors??{},metadataRegistry:e?.metadata??Oe,target:t,unrepresentable:e?.unrepresentable??"throw",override:e?.override??(()=>{}),io:e?.io??"output",counter:0,seen:new Map,cycles:e?.cycles??"ref",reused:e?.reused??"inline",external:e?.external??void 0}}function W(e,t,n={path:[],schemaPath:[]}){var i;const r=e._zod.def,s=t.seen.get(e);if(s)return s.count++,n.schemaPath.includes(e)&&(s.cycle=n.path),s.schema;const o={schema:{},count:1,cycle:void 0,path:n.path};t.seen.set(e,o);const c=e._zod.toJSONSchema?.();if(c)o.schema=c;else{const m={...n,schemaPath:[...n.schemaPath,e],path:n.path};if(e._zod.processJSONSchema)e._zod.processJSONSchema(t,o.schema,m);else{const I=o.schema,v=t.processors[r.type];if(!v)throw new Error(`[toJSONSchema]: Non-representable type encountered: ${r.type}`);v(e,t,I,m)}const y=e._zod.parent;y&&(o.ref||(o.ref=y),W(y,t,m),t.seen.get(y).isParent=!0)}const l=t.metadataRegistry.get(e);return l&&Object.assign(o.schema,l),t.io==="input"&&M(e)&&(delete o.schema.examples,delete o.schema.default),t.io==="input"&&"_prefault"in o.schema&&((i=o.schema).default??(i.default=o.schema._prefault)),delete o.schema._prefault,t.seen.get(e).schema}function jn(e,t){const n=e.seen.get(t);if(!n)throw new Error("Unprocessed schema. This is a bug in Zod.");const i=new Map;for(const o of e.seen.entries()){const c=e.metadataRegistry.get(o[0])?.id;if(c){const l=i.get(c);if(l&&l!==o[0])throw new Error(`Duplicate schema id "${c}" detected during JSON Schema conversion. Two different schemas cannot share the same id when converted together.`);i.set(c,o[0])}}const r=o=>{const c=e.target==="draft-2020-12"?"$defs":"definitions";if(e.external){const y=e.external.registry.get(o[0])?.id,I=e.external.uri??(B=>B);if(y)return{ref:I(y)};const v=o[1].defId??o[1].schema.id??`schema${e.counter++}`;return o[1].defId=v,{defId:v,ref:`${I("__shared")}#/${c}/${v}`}}if(o[1]===n)return{ref:"#"};const A=`#/${c}/`,m=o[1].schema.id??`__schema${e.counter++}`;return{defId:m,ref:A+m}},s=o=>{if(o[1].schema.$ref)return;const c=o[1],{ref:l,defId:A}=r(o);c.def={...c.schema},A&&(c.defId=A);const m=c.schema;for(const y in m)delete m[y];m.$ref=l};if(e.cycles==="throw")for(const o of e.seen.entries()){const c=o[1];if(c.cycle)throw new Error(`Cycle detected: #/${c.cycle?.join("/")}/<root>

Set the \`cycles\` parameter to \`"ref"\` to resolve cyclical schemas with defs.`)}for(const o of e.seen.entries()){const c=o[1];if(t===o[0]){s(o);continue}if(e.external){const A=e.external.registry.get(o[0])?.id;if(t!==o[0]&&A){s(o);continue}}if(e.metadataRegistry.get(o[0])?.id){s(o);continue}if(c.cycle){s(o);continue}if(c.count>1&&e.reused==="ref"){s(o);continue}}}function Vn(e,t){const n=e.seen.get(t);if(!n)throw new Error("Unprocessed schema. This is a bug in Zod.");const i=c=>{const l=e.seen.get(c);if(l.ref===null)return;const A=l.def??l.schema,m={...A},y=l.ref;if(l.ref=null,y){i(y);const v=e.seen.get(y),B=v.schema;if(B.$ref&&(e.target==="draft-07"||e.target==="draft-04"||e.target==="openapi-3.0")?(A.allOf=A.allOf??[],A.allOf.push(B)):Object.assign(A,B),Object.assign(A,m),c._zod.parent===y)for(const K in A)K==="$ref"||K==="allOf"||K in m||delete A[K];if(B.$ref&&v.def)for(const K in A)K==="$ref"||K==="allOf"||K in v.def&&JSON.stringify(A[K])===JSON.stringify(v.def[K])&&delete A[K]}const I=c._zod.parent;if(I&&I!==y){i(I);const v=e.seen.get(I);if(v?.schema.$ref&&(A.$ref=v.schema.$ref,v.def))for(const B in A)B==="$ref"||B==="allOf"||B in v.def&&JSON.stringify(A[B])===JSON.stringify(v.def[B])&&delete A[B]}e.override({zodSchema:c,jsonSchema:A,path:l.path??[]})};for(const c of[...e.seen.entries()].reverse())i(c[0]);const r={};if(e.target==="draft-2020-12"?r.$schema="https://json-schema.org/draft/2020-12/schema":e.target==="draft-07"?r.$schema="http://json-schema.org/draft-07/schema#":e.target==="draft-04"?r.$schema="http://json-schema.org/draft-04/schema#":e.target,e.external?.uri){const c=e.external.registry.get(t)?.id;if(!c)throw new Error("Schema is missing an `id` property");r.$id=e.external.uri(c)}Object.assign(r,n.def??n.schema);const s=e.metadataRegistry.get(t)?.id;s!==void 0&&r.id===s&&delete r.id;const o=e.external?.defs??{};for(const c of e.seen.entries()){const l=c[1];l.def&&l.defId&&(l.def.id===l.defId&&delete l.def.id,o[l.defId]=l.def)}e.external||Object.keys(o).length>0&&(e.target==="draft-2020-12"?r.$defs=o:r.definitions=o);try{const c=JSON.parse(JSON.stringify(r));return Object.defineProperty(c,"~standard",{value:{...t["~standard"],jsonSchema:{input:je(t,"input",e.processors),output:je(t,"output",e.processors)}},enumerable:!1,writable:!1}),c}catch{throw new Error("Error converting schema to JSON.")}}function M(e,t){const n=t??{seen:new Set};if(n.seen.has(e))return!1;n.seen.add(e);const i=e._zod.def;if(i.type==="transform")return!0;if(i.type==="array")return M(i.element,n);if(i.type==="set")return M(i.valueType,n);if(i.type==="lazy")return M(i.getter(),n);if(i.type==="promise"||i.type==="optional"||i.type==="nonoptional"||i.type==="nullable"||i.type==="readonly"||i.type==="default"||i.type==="prefault")return M(i.innerType,n);if(i.type==="intersection")return M(i.left,n)||M(i.right,n);if(i.type==="record"||i.type==="map")return M(i.keyType,n)||M(i.valueType,n);if(i.type==="pipe")return e._zod.traits.has("$ZodCodec")?!0:M(i.in,n)||M(i.out,n);if(i.type==="object"){for(const r in i.shape)if(M(i.shape[r],n))return!0;return!1}if(i.type==="union"){for(const r of i.options)if(M(r,n))return!0;return!1}if(i.type==="tuple"){for(const r of i.items)if(M(r,n))return!0;return!!(i.rest&&M(i.rest,n))}return!1}const $s=(e,t={})=>n=>{const i=qn({...n,processors:t});return W(e,i),jn(i,e),Vn(i,e)},je=(e,t,n={})=>i=>{const{libraryOptions:r,target:s}=i??{},o=qn({...r??{},target:s,io:t,processors:n});return W(e,o),jn(o,e),Vn(o,e)},ec={guid:"uuid",url:"uri",datetime:"date-time",json_string:"json-string",regex:""},tc=(e,t,n,i)=>{const r=n;r.type="string";const{minimum:s,maximum:o,format:c,patterns:l,contentEncoding:A}=e._zod.bag;if(typeof s=="number"&&(r.minLength=s),typeof o=="number"&&(r.maxLength=o),c&&(r.format=ec[c]??c,r.format===""&&delete r.format,c==="time"&&delete r.format),A&&(r.contentEncoding=A),l&&l.size>0){const m=[...l];m.length===1?r.pattern=m[0].source:m.length>1&&(r.allOf=[...m.map(y=>({...t.target==="draft-07"||t.target==="draft-04"||t.target==="openapi-3.0"?{type:"string"}:{},pattern:y.source}))])}},nc=(e,t,n,i)=>{const r=n,{minimum:s,maximum:o,format:c,multipleOf:l,exclusiveMaximum:A,exclusiveMinimum:m}=e._zod.bag;typeof c=="string"&&c.includes("int")?r.type="integer":r.type="number";const y=typeof m=="number"&&m>=(s??Number.NEGATIVE_INFINITY),I=typeof A=="number"&&A<=(o??Number.POSITIVE_INFINITY),v=t.target==="draft-04"||t.target==="openapi-3.0";y?v?(r.minimum=m,r.exclusiveMinimum=!0):r.exclusiveMinimum=m:typeof s=="number"&&(r.minimum=s),I?v?(r.maximum=A,r.exclusiveMaximum=!0):r.exclusiveMaximum=A:typeof o=="number"&&(r.maximum=o),typeof l=="number"&&(r.multipleOf=l)},ic=(e,t,n,i)=>{n.type="boolean"},rc=(e,t,n,i)=>{t.target==="openapi-3.0"?(n.type="string",n.nullable=!0,n.enum=[null]):n.type="null"},oc=(e,t,n,i)=>{if(t.unrepresentable==="throw")throw new Error("Undefined cannot be represented in JSON Schema")},ac=(e,t,n,i)=>{n.not={}},sc=(e,t,n,i)=>{},cc=(e,t,n,i)=>{const r=e._zod.def,s=dn(r.entries);s.every(o=>typeof o=="number")&&(n.type="number"),s.every(o=>typeof o=="string")&&(n.type="string"),n.enum=s},lc=(e,t,n,i)=>{const r=e._zod.def,s=[];for(const o of r.values)if(o===void 0){if(t.unrepresentable==="throw")throw new Error("Literal `undefined` cannot be represented in JSON Schema")}else if(typeof o=="bigint"){if(t.unrepresentable==="throw")throw new Error("BigInt literals cannot be represented in JSON Schema");s.push(Number(o))}else s.push(o);if(s.length!==0)if(s.length===1){const o=s[0];n.type=o===null?"null":typeof o,t.target==="draft-04"||t.target==="openapi-3.0"?n.enum=[o]:n.const=o}else s.every(o=>typeof o=="number")&&(n.type="number"),s.every(o=>typeof o=="string")&&(n.type="string"),s.every(o=>typeof o=="boolean")&&(n.type="boolean"),s.every(o=>o===null)&&(n.type="null"),n.enum=s},Ac=(e,t,n,i)=>{if(t.unrepresentable==="throw")throw new Error("Custom types cannot be represented in JSON Schema")},uc=(e,t,n,i)=>{if(t.unrepresentable==="throw")throw new Error("Transforms cannot be represented in JSON Schema")},dc=(e,t,n,i)=>{const r=n,s=e._zod.def,{minimum:o,maximum:c}=e._zod.bag;typeof o=="number"&&(r.minItems=o),typeof c=="number"&&(r.maxItems=c),r.type="array",r.items=W(s.element,t,{...i,path:[...i.path,"items"]})},hc=(e,t,n,i)=>{const r=n,s=e._zod.def;r.type="object",r.properties={};const o=s.shape;for(const A in o)r.properties[A]=W(o[A],t,{...i,path:[...i.path,"properties",A]});const c=new Set(Object.keys(o)),l=new Set([...c].filter(A=>{const m=s.shape[A]._zod;return t.io==="input"?m.optin===void 0:m.optout===void 0}));l.size>0&&(r.required=Array.from(l)),s.catchall?._zod.def.type==="never"?r.additionalProperties=!1:s.catchall?s.catchall&&(r.additionalProperties=W(s.catchall,t,{...i,path:[...i.path,"additionalProperties"]})):t.io==="output"&&(r.additionalProperties=!1)},fc=(e,t,n,i)=>{const r=e._zod.def,s=r.inclusive===!1,o=r.options.map((c,l)=>W(c,t,{...i,path:[...i.path,s?"oneOf":"anyOf",l]}));s?n.oneOf=o:n.anyOf=o},pc=(e,t,n,i)=>{const r=e._zod.def,s=W(r.left,t,{...i,path:[...i.path,"allOf",0]}),o=W(r.right,t,{...i,path:[...i.path,"allOf",1]}),c=A=>"allOf"in A&&Object.keys(A).length===1,l=[...c(s)?s.allOf:[s],...c(o)?o.allOf:[o]];n.allOf=l},mc=(e,t,n,i)=>{const r=n,s=e._zod.def;r.type="object";const o=s.keyType,l=o._zod.bag?.patterns;if(s.mode==="loose"&&l&&l.size>0){const m=W(s.valueType,t,{...i,path:[...i.path,"patternProperties","*"]});r.patternProperties={};for(const y of l)r.patternProperties[y.source]=m}else(t.target==="draft-07"||t.target==="draft-2020-12")&&(r.propertyNames=W(s.keyType,t,{...i,path:[...i.path,"propertyNames"]})),r.additionalProperties=W(s.valueType,t,{...i,path:[...i.path,"additionalProperties"]});const A=o._zod.values;if(A){const m=[...A].filter(y=>typeof y=="string"||typeof y=="number");m.length>0&&(r.required=m)}},gc=(e,t,n,i)=>{const r=e._zod.def,s=W(r.innerType,t,i),o=t.seen.get(e);t.target==="openapi-3.0"?(o.ref=r.innerType,n.nullable=!0):n.anyOf=[s,{type:"null"}]},wc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType},bc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType,n.default=JSON.parse(JSON.stringify(r.defaultValue))},yc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType,t.io==="input"&&(n._prefault=JSON.parse(JSON.stringify(r.defaultValue)))},vc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType;let o;try{o=r.catchValue(void 0)}catch{throw new Error("Dynamic catch values are not supported in JSON Schema")}n.default=o},kc=(e,t,n,i)=>{const r=e._zod.def,s=r.in._zod.traits.has("$ZodTransform"),o=t.io==="input"?s?r.out:r.in:r.out;W(o,t,i);const c=t.seen.get(e);c.ref=o},Ic=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType,n.readOnly=!0},Xn=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType},xc=(e,t,n,i)=>{const r=e._zod.innerType;W(r,t,i);const s=t.seen.get(e);s.ref=r},Sc=u("ZodISODateTime",(e,t)=>{wa.init(e,t),Z.init(e,t)});function Cc(e){return Es(Sc,e)}const Ec=u("ZodISODate",(e,t)=>{ba.init(e,t),Z.init(e,t)});function Bc(e){return Bs(Ec,e)}const _c=u("ZodISOTime",(e,t)=>{ya.init(e,t),Z.init(e,t)});function Dc(e){return _s(_c,e)}const Nc=u("ZodISODuration",(e,t)=>{va.init(e,t),Z.init(e,t)});function Fc(e){return Ds(Nc,e)}const H=u("ZodError",(e,t)=>{wn.init(e,t),e.name="ZodError",Object.defineProperties(e,{format:{value:n=>so(e,n)},flatten:{value:n=>ao(e,n)},addIssue:{value:n=>{e.issues.push(n),e.message=JSON.stringify(e.issues,ht,2)}},addIssues:{value:n=>{e.issues.push(...n),e.message=JSON.stringify(e.issues,ht,2)}},isEmpty:{get(){return e.issues.length===0}}})},{Parent:Error}),Zc=gt(H),Rc=wt(H),Qc=Je(H),Oc=Ye(H),Uc=Ao(H),Wc=uo(H),zc=ho(H),Kc=fo(H),Tc=po(H),Gc=mo(H),Mc=go(H),Jc=wo(H),$n=new WeakMap;function Ue(e,t,n){const i=Object.getPrototypeOf(e);let r=$n.get(i);if(r||(r=new Set,$n.set(i,r)),!r.has(t)){r.add(t);for(const s in n){const o=n[s];Object.defineProperty(i,s,{configurable:!0,enumerable:!1,get(){const c=o.bind(this);return Object.defineProperty(this,s,{configurable:!0,writable:!0,enumerable:!0,value:c}),c},set(c){Object.defineProperty(this,s,{configurable:!0,writable:!0,enumerable:!0,value:c})}})}}}const N=u("ZodType",(e,t)=>(D.init(e,t),Object.assign(e["~standard"],{jsonSchema:{input:je(e,"input"),output:je(e,"output")}}),e.toJSONSchema=$s(e,{}),e.def=t,e.type=t.type,Object.defineProperty(e,"_def",{value:t}),e.parse=(n,i)=>Zc(e,n,i,{callee:e.parse}),e.safeParse=(n,i)=>Qc(e,n,i),e.parseAsync=async(n,i)=>Rc(e,n,i,{callee:e.parseAsync}),e.safeParseAsync=async(n,i)=>Oc(e,n,i),e.spa=e.safeParseAsync,e.encode=(n,i)=>Uc(e,n,i),e.decode=(n,i)=>Wc(e,n,i),e.encodeAsync=async(n,i)=>zc(e,n,i),e.decodeAsync=async(n,i)=>Kc(e,n,i),e.safeEncode=(n,i)=>Tc(e,n,i),e.safeDecode=(n,i)=>Gc(e,n,i),e.safeEncodeAsync=async(n,i)=>Mc(e,n,i),e.safeDecodeAsync=async(n,i)=>Jc(e,n,i),Ue(e,"ZodType",{check(...n){const i=this.def;return this.clone(le(i,{checks:[...i.checks??[],...n.map(r=>typeof r=="function"?{_zod:{check:r,def:{check:"custom"},onattach:[]}}:r)]}),{parent:!0})},with(...n){return this.check(...n)},clone(n,i){return Ae(this,n,i)},brand(){return this},register(n,i){return n.add(this,i),this},refine(n,i){return this.check(Wl(n,i))},superRefine(n,i){return this.check(zl(n,i))},overwrite(n){return this.check(Se(n))},optional(){return ci(this)},exactOptional(){return xl(this)},nullable(){return li(this)},nullish(){return ci(li(this))},nonoptional(n){return Dl(this,n)},array(){return w(this)},or(n){return q([this,n])},and(n){return bl(this,n)},transform(n){return ui(this,kl(n))},default(n){return El(this,n)},prefault(n){return _l(this,n)},catch(n){return Fl(this,n)},pipe(n){return ui(this,n)},readonly(){return Ql(this)},describe(n){const i=this.clone();return Oe.add(i,{description:n}),i},meta(...n){if(n.length===0)return Oe.get(this);const i=this.clone();return Oe.add(i,n[0]),i},isOptional(){return this.safeParse(void 0).success},isNullable(){return this.safeParse(null).success},apply(n){return n(this)}}),Object.defineProperty(e,"description",{get(){return Oe.get(e)?.description},configurable:!0}),e)),ei=u("_ZodString",(e,t)=>{bt.init(e,t),N.init(e,t),e._zod.processJSONSchema=(i,r,s)=>tc(e,i,r);const n=e._zod.bag;e.format=n.format??null,e.minLength=n.minimum??null,e.maxLength=n.maximum??null,Ue(e,"_ZodString",{regex(...i){return this.check(Ws(...i))},includes(...i){return this.check(Ts(...i))},startsWith(...i){return this.check(Gs(...i))},endsWith(...i){return this.check(Ms(...i))},min(...i){return this.check(qe(...i))},max(...i){return this.check(Pn(...i))},length(...i){return this.check(Hn(...i))},nonempty(...i){return this.check(qe(1,...i))},lowercase(i){return this.check(zs(i))},uppercase(i){return this.check(Ks(i))},trim(){return this.check(Ys())},normalize(...i){return this.check(Js(...i))},toLowerCase(){return this.check(Ls())},toUpperCase(){return this.check(Ps())},slugify(){return this.check(Hs())}})}),Yc=u("ZodString",(e,t)=>{bt.init(e,t),ei.init(e,t),e.email=n=>e.check(as(Lc,n)),e.url=n=>e.check(us(Pc,n)),e.jwt=n=>e.check(Cs(cl,n)),e.emoji=n=>e.check(ds(Hc,n)),e.guid=n=>e.check(Mn(ti,n)),e.uuid=n=>e.check(ss(Ve,n)),e.uuidv4=n=>e.check(cs(Ve,n)),e.uuidv6=n=>e.check(ls(Ve,n)),e.uuidv7=n=>e.check(As(Ve,n)),e.nanoid=n=>e.check(hs(qc,n)),e.guid=n=>e.check(Mn(ti,n)),e.cuid=n=>e.check(fs(jc,n)),e.cuid2=n=>e.check(ps(Vc,n)),e.ulid=n=>e.check(ms(Xc,n)),e.base64=n=>e.check(Is(ol,n)),e.base64url=n=>e.check(xs(al,n)),e.xid=n=>e.check(gs($c,n)),e.ksuid=n=>e.check(ws(el,n)),e.ipv4=n=>e.check(bs(tl,n)),e.ipv6=n=>e.check(ys(nl,n)),e.cidrv4=n=>e.check(vs(il,n)),e.cidrv6=n=>e.check(ks(rl,n)),e.e164=n=>e.check(Ss(sl,n)),e.datetime=n=>e.check(Cc(n)),e.date=n=>e.check(Bc(n)),e.time=n=>e.check(Dc(n)),e.duration=n=>e.check(Fc(n))});function a(e){return os(Yc,e)}const Z=u("ZodStringFormat",(e,t)=>{F.init(e,t),ei.init(e,t)}),Lc=u("ZodEmail",(e,t)=>{la.init(e,t),Z.init(e,t)}),ti=u("ZodGUID",(e,t)=>{sa.init(e,t),Z.init(e,t)}),Ve=u("ZodUUID",(e,t)=>{ca.init(e,t),Z.init(e,t)}),Pc=u("ZodURL",(e,t)=>{Aa.init(e,t),Z.init(e,t)}),Hc=u("ZodEmoji",(e,t)=>{ua.init(e,t),Z.init(e,t)}),qc=u("ZodNanoID",(e,t)=>{da.init(e,t),Z.init(e,t)}),jc=u("ZodCUID",(e,t)=>{ha.init(e,t),Z.init(e,t)}),Vc=u("ZodCUID2",(e,t)=>{fa.init(e,t),Z.init(e,t)}),Xc=u("ZodULID",(e,t)=>{pa.init(e,t),Z.init(e,t)}),$c=u("ZodXID",(e,t)=>{ma.init(e,t),Z.init(e,t)}),el=u("ZodKSUID",(e,t)=>{ga.init(e,t),Z.init(e,t)}),tl=u("ZodIPv4",(e,t)=>{ka.init(e,t),Z.init(e,t)}),nl=u("ZodIPv6",(e,t)=>{Ia.init(e,t),Z.init(e,t)}),il=u("ZodCIDRv4",(e,t)=>{xa.init(e,t),Z.init(e,t)}),rl=u("ZodCIDRv6",(e,t)=>{Sa.init(e,t),Z.init(e,t)}),ol=u("ZodBase64",(e,t)=>{Ca.init(e,t),Z.init(e,t)}),al=u("ZodBase64URL",(e,t)=>{Ba.init(e,t),Z.init(e,t)}),sl=u("ZodE164",(e,t)=>{_a.init(e,t),Z.init(e,t)}),cl=u("ZodJWT",(e,t)=>{Na.init(e,t),Z.init(e,t)}),ni=u("ZodNumber",(e,t)=>{_n.init(e,t),N.init(e,t),e._zod.processJSONSchema=(i,r,s)=>nc(e,i,r),Ue(e,"ZodNumber",{gt(i,r){return this.check(Yn(i,r))},gte(i,r){return this.check(kt(i,r))},min(i,r){return this.check(kt(i,r))},lt(i,r){return this.check(Jn(i,r))},lte(i,r){return this.check(vt(i,r))},max(i,r){return this.check(vt(i,r))},int(i){return this.check(ii(i))},safe(i){return this.check(ii(i))},positive(i){return this.check(Yn(0,i))},nonnegative(i){return this.check(kt(0,i))},negative(i){return this.check(Jn(0,i))},nonpositive(i){return this.check(vt(0,i))},multipleOf(i,r){return this.check(Ln(i,r))},step(i,r){return this.check(Ln(i,r))},finite(){return this}});const n=e._zod.bag;e.minValue=Math.max(n.minimum??Number.NEGATIVE_INFINITY,n.exclusiveMinimum??Number.NEGATIVE_INFINITY)??null,e.maxValue=Math.min(n.maximum??Number.POSITIVE_INFINITY,n.exclusiveMaximum??Number.POSITIVE_INFINITY)??null,e.isInt=(n.format??"").includes("int")||Number.isSafeInteger(n.multipleOf??.5),e.isFinite=!0,e.format=n.format??null});function d(e){return Ns(ni,e)}const ll=u("ZodNumberFormat",(e,t)=>{Fa.init(e,t),ni.init(e,t)});function ii(e){return Fs(ll,e)}const Al=u("ZodBoolean",(e,t)=>{Za.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>ic(e,n,i)});function S(e){return Zs(Al,e)}const ul=u("ZodUndefined",(e,t)=>{Ra.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>oc(e,n)});function dl(e){return Rs(ul,e)}const hl=u("ZodNull",(e,t)=>{Qa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>rc(e,n,i)});function Xe(e){return Qs(hl,e)}const fl=u("ZodUnknown",(e,t)=>{Oa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>sc()});function j(){return Os(fl)}const pl=u("ZodNever",(e,t)=>{Ua.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>ac(e,n,i)});function Ce(e){return Us(pl,e)}const ml=u("ZodArray",(e,t)=>{Wa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>dc(e,n,i,r),e.element=t.element,Ue(e,"ZodArray",{min(n,i){return this.check(qe(n,i))},nonempty(n){return this.check(qe(1,n))},max(n,i){return this.check(Pn(n,i))},length(n,i){return this.check(Hn(n,i))},unwrap(){return this.element}})});function w(e,t){return qs(ml,e,t)}const ri=u("ZodObject",(e,t)=>{Ka.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>hc(e,n,i,r),E(e,"shape",()=>t.shape),Ue(e,"ZodObject",{keyof(){return g(Object.keys(this._zod.def.shape))},catchall(n){return this.clone({...this._zod.def,catchall:n})},passthrough(){return this.clone({...this._zod.def,catchall:j()})},loose(){return this.clone({...this._zod.def,catchall:j()})},strict(){return this.clone({...this._zod.def,catchall:Ce()})},strip(){return this.clone({...this._zod.def,catchall:void 0})},extend(n){return eo(this,n)},safeExtend(n){return to(this,n)},merge(n){return no(this,n)},pick(n){return Xr(this,n)},omit(n){return $r(this,n)},partial(...n){return io(si,this,n[0])},required(...n){return ro(Ai,this,n[0])}})});function f(e,t){const n={type:"object",shape:e??{},...k(t)};return new ri(n)}function b(e,t){return new ri({type:"object",shape:e,catchall:Ce(),...k(t)})}const oi=u("ZodUnion",(e,t)=>{Rn.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>fc(e,n,i,r),e.options=t.options});function q(e,t){return new oi({type:"union",options:e,...k(t)})}const gl=u("ZodDiscriminatedUnion",(e,t)=>{oi.init(e,t),Ta.init(e,t)});function R(e,t,n){return new gl({type:"union",options:t,discriminator:e,...k(n)})}const wl=u("ZodIntersection",(e,t)=>{Ga.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>pc(e,n,i,r)});function bl(e,t){return new wl({type:"intersection",left:e,right:t})}const ai=u("ZodRecord",(e,t)=>{Ma.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>mc(e,n,i,r),e.keyType=t.keyType,e.valueType=t.valueType});function V(e,t,n){return!t||!t._zod?new ai({type:"record",keyType:a(),valueType:e,...k(t)}):new ai({type:"record",keyType:e,valueType:t,...k(n)})}const It=u("ZodEnum",(e,t)=>{Ja.init(e,t),N.init(e,t),e._zod.processJSONSchema=(i,r,s)=>cc(e,i,r),e.enum=t.entries,e.options=Object.values(t.entries);const n=new Set(Object.keys(t.entries));e.extract=(i,r)=>{const s={};for(const o of i)if(n.has(o))s[o]=t.entries[o];else throw new Error(`Key ${o} not found in enum`);return new It({...t,checks:[],...k(r),entries:s})},e.exclude=(i,r)=>{const s={...t.entries};for(const o of i)if(n.has(o))delete s[o];else throw new Error(`Key ${o} not found in enum`);return new It({...t,checks:[],...k(r),entries:s})}});function g(e,t){const n=Array.isArray(e)?Object.fromEntries(e.map(i=>[i,i])):e;return new It({type:"enum",entries:n,...k(t)})}const yl=u("ZodLiteral",(e,t)=>{Ya.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>lc(e,n,i),e.values=new Set(t.values),Object.defineProperty(e,"value",{get(){if(t.values.length>1)throw new Error("This schema contains multiple valid literal values. Use `.values` instead.");return t.values[0]}})});function p(e,t){return new yl({type:"literal",values:Array.isArray(e)?e:[e],...k(t)})}const vl=u("ZodTransform",(e,t)=>{La.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>uc(e,n),e._zod.parse=(n,i)=>{if(i.direction==="backward")throw new un(e.constructor.name);n.addIssue=s=>{if(typeof s=="string")n.issues.push(Qe(s,n.value,t));else{const o=s;o.fatal&&(o.continue=!1),o.code??(o.code="custom"),o.input??(o.input=n.value),o.inst??(o.inst=e),n.issues.push(Qe(o))}};const r=t.transform(n.value,n);return r instanceof Promise?r.then(s=>(n.value=s,n.fallback=!0,n)):(n.value=r,n.fallback=!0,n)}});function kl(e){return new vl({type:"transform",transform:e})}const si=u("ZodOptional",(e,t)=>{Un.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Xn(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function ci(e){return new si({type:"optional",innerType:e})}const Il=u("ZodExactOptional",(e,t)=>{Pa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Xn(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function xl(e){return new Il({type:"optional",innerType:e})}const Sl=u("ZodNullable",(e,t)=>{Ha.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>gc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function li(e){return new Sl({type:"nullable",innerType:e})}const Cl=u("ZodDefault",(e,t)=>{qa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>bc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType,e.removeDefault=e.unwrap});function El(e,t){return new Cl({type:"default",innerType:e,get defaultValue(){return typeof t=="function"?t():mn(t)}})}const Bl=u("ZodPrefault",(e,t)=>{ja.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>yc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function _l(e,t){return new Bl({type:"prefault",innerType:e,get defaultValue(){return typeof t=="function"?t():mn(t)}})}const Ai=u("ZodNonOptional",(e,t)=>{Va.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>wc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function Dl(e,t){return new Ai({type:"nonoptional",innerType:e,...k(t)})}const Nl=u("ZodCatch",(e,t)=>{Xa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>vc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType,e.removeCatch=e.unwrap});function Fl(e,t){return new Nl({type:"catch",innerType:e,catchValue:typeof t=="function"?t:()=>t})}const Zl=u("ZodPipe",(e,t)=>{$a.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>kc(e,n,i,r),e.in=t.in,e.out=t.out});function ui(e,t){return new Zl({type:"pipe",in:e,out:t})}const Rl=u("ZodReadonly",(e,t)=>{es.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Ic(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function Ql(e){return new Rl({type:"readonly",innerType:e})}const Ol=u("ZodLazy",(e,t)=>{ts.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>xc(e,n,i,r),e.unwrap=()=>e._zod.def.getter()});function di(e){return new Ol({type:"lazy",getter:e})}const Ul=u("ZodCustom",(e,t)=>{ns.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Ac(e,n)});function Wl(e,t={}){return js(Ul,e,t)}function zl(e,t){return Vs(e,t)}const Ee=["fm","inf"],$e="inf";function Kl(e){return[$e,...Ee.filter(t=>t!==$e)].map(t=>`data-${t}-${e}`)}const xt=f({id:a().min(1).max(64).regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),sharedId:a().min(1).max(64).optional(),target:a().min(1).max(200),title:a().min(1).max(200),consequence:a().min(1).max(500),instructions:w(a().min(1).max(2e3)).min(1).max(20),criterion:a().min(1).max(1e3),prerequisites:w(a().min(1).max(64)).max(50),completion:R("kind",[f({kind:p("manual"),label:a().min(1).max(64)}),f({kind:p("device-version"),deviceId:a().min(1).max(64),minVersion:a().regex(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/)})])}),St=w(xt).max(20),hi=xt.pick({title:!0,consequence:!0,instructions:!0,criterion:!0}).partial(),Tl=f({operationId:a().min(1).max(128),actor:g(["crewmate","firstmate"]),taskId:a().optional(),label:a().min(1).max(160),at:d(),reason:a().min(1).max(500),generation:d().int().positive(),previous:hi});f({action:a().min(1).max(128),source:a().min(1).max(64),actionId:a().min(1).max(64),expectedGeneration:d().int().positive(),patch:hi,reason:a().min(1).max(500),operationId:a().min(1).max(128),sameAction:S()}),f({requirements:w(f({source:a(),offer:a(),head:a().optional(),action:xt,corrections:w(Tl).optional()})),generation:d().int().positive(),state:g(["blocked","ready","deferred","confirmed","checked","cancelled"]),cardId:a(),presentedGeneration:d().int().nonnegative(),activatedAt:d(),completedAt:d().optional(),cancelledReason:a().optional()}),f({cardId:a(),state:g(["blocked","ready","deferred","confirmed","checked","cancelled"]),result:a()});const Gl=g(["quick","standard","reviewed"]);g(["pass","findings","blocked"]),g(["low","medium","high"]);const Ml=g(["error","warning","info"]),Jl=g(["auto-fix","ask-user","no-op"]);f({id:a().trim().min(1).max(64),severity:Ml,file:a().trim().min(1).optional(),line:d().int().min(1).optional(),text:a().trim().min(1).max(4e3),action:Jl});const fi=f({kind:p("settle"),mode:g(["merge","discard"]),confirm:p(!0).optional(),proceedWithOpen:p(!0).optional()}),pi=f({kind:p("request_merge"),review:a().min(1).max(64)}),mi=f({kind:p("request_write"),ask:a().min(1).max(64),integration:g(["always","once","deny"]).optional()}),gi=g(["link","command","user-command"]),wi=f({deviceId:a().min(1).max(64),providerId:a().min(1).max(256)}),bi=f({deviceId:a().min(1).max(64),host:a().min(1).max(253)}),yi=f({kind:p("open"),target:g(["settings","subscriptions","projects","devices","browser"]),savedSignIn:p(!0).optional(),signIn:a().min(1).max(253).optional(),make:gi.optional(),remove:a().min(1).max(64).optional(),add:a().min(1).max(255).optional(),update:a().min(1).max(64).optional(),signInOn:wi.optional(),forgeSignInOn:bi.optional()}),Yl=["restore-account","move-flagship","retry-firstmate","try-again","add-plugin","decline-plugin","apply-project-change","decline-project-change","add-project","decline-project","continue-task","move-task","stop-task","start-task","ask-again","confirm-required-action","defer-required-action"];g(["start-task","start-again","stop-task","continue-task","drop-task","queue-task","unqueue-task","show-card"]),f({parts:w(a().min(1).max(64)).max(64),waiting:w(a().min(1).max(64)).max(64),underway:w(a().min(1).max(64)).max(64)}),b({panel:a().min(1).max(40)});const Ll=f({kind:p("host"),op:g(Yl),arg:a().optional()}),vi=R("kind",[fi,pi,mi,yi,Ll]);R("kind",[fi,pi,mi,yi]);const Ct=g(["crewmate","firstmate","host"]),Pl=/<!--[\s\S]*?(?:-->|$)|<(script|style)(?=[\s>/])[^>]*>(?:[\s\S]*?<\/\1\s*>|[\s\S]*$)|<(\/?)(figure|canvas)(?=[\s>/])[^>]*>/gi;function Hl(e){let t=0;for(const[,n,i,r]of e.matchAll(Pl)){const s=(n??r??"").toLowerCase();if(s==="style"||s==="canvas"&&!i||s==="script"&&t===0)return!0;s==="figure"&&(t=i?Math.max(0,t-1):t+1)}return!1}const Et=f({id:a(),label:a(),variant:g(["primary","secondary","ghost","danger"]).optional(),default:S().optional(),keepsOpen:S().optional(),effect:vi.optional(),danger:S().optional(),care:Gl.optional(),passes:p("checks").optional()}),ql=b({id:a(),kind:g(["mp4","gif"]),width:d().int().positive(),height:d().int().positive(),durationMs:d().int().positive(),bytes:d().int().positive(),sha256:a().regex(/^[0-9a-f]{64}$/)}),ki=b({sha256:a().regex(/^[0-9a-f]{64}$/).optional(),id:a(),alt:a(),width:d().int().positive(),height:d().int().positive(),group:d().int().nonnegative(),demo:ql.optional()}),Ii=32,xi=R("kind",[b({kind:p("browser"),label:a().min(1).max(Ii),taskId:a().min(1).max(64),session:a().min(1).max(64),generation:d().int().positive(),handoff:p(!0).optional()}),b({kind:p("page"),label:a().min(1).max(Ii),taskId:a().min(1).max(64),path:a().min(1).max(256)})]),fe=b({level:g(["low","medium","high"]),why:a().min(1).max(100)}),jl=b({blast:fe,behavior:fe,undo:fe,evidence:fe,sensitivity:fe,novelty:fe,deps:fe}),Bt=f({declared:jl});function Vl(e){return e.reviewTaskId||e.actions.some(t=>AA(t))?!0:e.risk!==void 0&&e.actions.length===0}function Xl(e){return Vl(e)||e.actions.some(t=>uA(t))}function $l(e){const t=Math.max(...Ee.map(r=>e.lastIndexOf(`<div class="${r}-facts" data-facts>`)));if(t<0)return;const n=e.indexOf("</div>",t);if(n<0)return;const i=n+6;return{body:e.slice(0,t)+e.slice(i),facts:e.slice(t,i),at:t}}const _t=g(["regular","wide","full"]),Si=g(["answer","close-out"]),eA=b({at:d(),added:d().int().nonnegative(),removed:d().int().nonnegative(),rewritten:S(),marks:w(d().int().nonnegative()).max(512)});g(["chrome","frame"]);const et=256,Dt=256,Ci=200,Nt=16384;`${(64*1024).toLocaleString("en-US")}`;const Ei=500,Bi=b({name:a().min(1).max(Ci),values:w(a().max(Nt)).max(Dt),labels:w(a().max(Nt)).max(Dt).optional(),changed:S(),json:p(!0).optional(),written:a().min(1).max(4e3).optional()}),Be=w(Bi).max(et);b({answers:Be});const Ft=500,tA=64*1024,nA=["single","multiple","text","opaque"],_i=["no-prompt","conflicting-prompt","label-truncated","duplicate-values","mixed-controls","opaque"],iA=b({value:a().max(Nt),label:a().max(Ft).nullable(),authoredDefault:S(),disabled:S(),hidden:S()}),rA=b({name:a().min(1).max(Ci),kind:g(nA),control:g(["radio","checkbox","select","select-multiple","text","textarea","hidden","staged","mixed"]),prompt:a().max(Ft).nullable(),promptBasis:g(["legend","labelledby","aria-label","label"]).nullable(),options:w(iA).max(Dt),defaultBasis:g(["authored","implicit-first","none"]),required:S(),gaps:w(g(_i)).max(_i.length),complete:S(),writeIn:p(!0).optional()}),Zt=w(rA).max(et),Di=g(["no-fresh-reading","too-large","invalid"]);b({id:a().min(8).max(64),lifecycleId:a().max(64).optional(),offerId:a().max(64).optional(),reading:g(["fresh","fallback","none"]).optional(),remounted:p(!0).optional(),questions:Zt.optional(),questionsGap:Di.optional()});const oA=["asked","said","chose","automation","from"],aA=b({at:d(),text:a(),kind:g(oA).optional(),choice:a().optional(),key:a().optional(),through:d().int().positive().optional()});b({id:a(),taskId:a().optional(),reviewTaskId:a().optional(),author:Ct,priority:d(),title:a(),meta:a(),model:a().optional(),place:a().optional(),body:a(),requiredActions:St.optional(),actions:w(Et),status:g(["streaming","ready"]),createdAt:d(),pictures:w(ki).optional(),width:_t.optional(),attachment:xi.optional(),risk:Bt.optional(),replies:p(!1).optional(),answeredBy:p("firstmate").optional(),holdsPlace:p(!0).optional(),asking:p(!0).optional(),designOnly:p(!0).optional(),continues:p(!0).optional(),answering:p(!0).optional(),awaiting:Si.optional(),minimized:p(!0).optional(),sentBackAt:d().int().nonnegative().optional(),lifecycleId:a().max(64).optional(),offerId:a().max(64).optional(),changes:eA.optional(),asked:aA.optional(),seen:S().optional(),currentUpdateId:a().max(64).optional(),currentUpdateSeen:S().optional()});const Ni=g(["captain","crewmate","firstmate","host"]),tt=512,Fi=b({id:d().int().nonnegative().max(tt+1),label:a().max(160),region:g(["body","title","buttons","whole","preview"]),start:d().int().nonnegative().optional()}),sA=b({lifecycleId:a().min(1).max(64),offerId:a().min(1).max(64),previousOfferId:a().min(1).max(64),released:S(),targets:w(Fi).max(tt+2),removed:d().int().nonnegative()}),cA=b({offerId:a().min(1).max(64),targets:w(Fi).max(tt+2)}),Zi=b({actor:g(["crewmate","firstmate"]),taskId:a().min(1).max(64).optional(),label:a().min(1).max(160)});f({effect:g(["created","revised","reply-only","unchanged","refused"]),cardId:a(),title:a().optional(),lifecycleId:a().optional(),revision:a().optional(),generation:d().int().optional(),contributor:Zi,replyId:d().int().optional(),answered:d().int().optional(),alreadyAnswered:f({messageId:d().int(),by:a(),text:a()}).optional(),clarification:p(!0).optional(),unchanged:w(a()).optional(),display:g(["available","held"]),responseId:a().optional(),refusal:a().optional(),repeated:p(!0).optional()});const Ri=b({revision:sA.optional(),revisionShown:cA.optional(),contributor:Zi.optional(),answersMessage:d().int().positive().optional(),clarification:p(!0).optional(),id:d(),cardId:a(),who:Ni,text:a(),at:d(),answers:Be.optional()});b({cardId:a(),messages:w(Ri)});const lA=["chose","dismissed","author-withdrawal","host-withdrawal","task-retired","duplicate","unknown"];b({id:a(),reviewTaskId:a().optional(),taskId:a().optional(),author:Ct,title:a(),meta:a(),model:a().optional(),body:a(),actions:w(Et.omit({effect:!0})),width:_t.optional(),requiredActions:St.optional(),risk:Bt.optional(),ending:b({how:g(lA),at:d(),actionId:a().optional(),label:a().optional(),by:g(["captain","firstmate","crewmate","host","frame"]).optional()}),answers:Be,messages:w(Ri)}),b({mimeType:g(["image/png","image/jpeg","image/gif","image/webp"]),data:a().min(1).max(75e5),name:a().max(120).optional()});function AA(e){return e.effect?.kind==="settle"?e.effect:void 0}function uA(e){return e.effect?.kind==="request_merge"?e.effect:void 0}f({kind:p("open"),target:g(["settings","subscriptions","projects","devices","browser"]),browser:f({taskId:a(),session:a(),generation:d().int().positive(),cardId:a()}).optional(),restoreAccountId:a().optional(),signIn:a().optional(),make:gi.optional(),remove:a().optional(),add:a().optional(),update:a().optional(),signInOn:wi.optional(),forgeSignInOn:bi.optional()});const Rt=b({fidelity:g(["matched","mismatched","legacy-missing","unavailable"]),reportedOfferId:a().max(64).optional(),reportedLifecycleId:a().max(64).optional()}),dA=b({at:d(),taskId:a(),key:a(),kind:a(),status:a(),activity:a().nullable(),parentId:a().nullable(),gate:b({kind:a(),ref:a().optional()}).nullable(),delivery:b({mode:a(),changeLabel:a().optional(),headSha:a().optional(),checks:a().optional(),checksAt:d().optional(),review:a().optional(),reviewSha:a().optional(),reviewedAt:d().optional(),settlePending:S()}).nullable(),blockers:w(b({id:a(),status:a()})),asks:w(a())}),Qi=500;b({reviewTaskId:a().optional(),basis:g(["emitted","put","legacy-initial-snapshot"]),fingerprint:a(),author:Ct,title:a(),meta:a(),model:a().optional(),place:a().optional(),body:a(),requiredActions:St.optional(),actions:w(Et),pictures:w(ki).optional(),width:_t.optional(),attachment:xi.optional(),risk:Bt.optional(),asking:p(!0).optional(),designOnly:p(!0).optional(),continues:p(!0).optional(),answering:p(!0).optional(),holdsPlace:p(!0).optional()}),b({state:g(["available","waiting"]),waitingOn:Si.optional(),cause:g(["emit","revise","put","close-out","reply","answered","restore"]),closeOut:g(["report","idle","turn-end","restart"]).optional(),replaces:a().optional(),lifecycle:g(["started","reopened","legacy-initial-snapshot"]).optional(),predecessor:a().optional()}),b({actionId:a(),recognized:S(),label:a().nullable(),closes:S(),keepsOpen:S(),effect:vi.nullable(),frameValue:a().optional(),answers:Be.optional(),display:Rt,reading:g(["fresh","fallback","none"]).optional(),remounted:p(!0).optional(),questions:Zt.optional(),questionsGap:g(["absent","no-fresh-reading","too-large","invalid"]).optional(),context:dA.optional(),contextGap:g(["no-task","task-missing"]).optional(),interactionSource:g(["shell","host"])}),b({messageId:d().int(),who:Ni,interim:p(!0).optional(),answers:Be.optional(),display:Rt.optional()}),b({reason:g(["dismissed","author-withdrawal","host-withdrawal","task-retired","duplicate"]),note:a().max(Qi).optional(),duplicateOf:a().optional(),display:Rt.optional()}),b({interactionId:a(),outcome:g(["completed","refused","failed","queued"]),note:a().max(Qi).optional()}),b({updateId:a().max(64).optional()});const Qt=200,L=a().min(1).max(64),Ot=a().regex(/^[cf]-[a-z0-9]{6}$/),re=f({state:p("unavailable"),reason:a()}),oe=f({id:a(),kind:g(["concept","finding"]),title:a(),retired:S()}),pe=g(["checked","unchecked","recheck","differing","superseded","retired"]),Oi=f({recheck:S(),differing:S()}),hA=f({scope:L,name:a(),private:S(),concepts:d().int().nonnegative(),findings:d().int().nonnegative(),directions:d().int().nonnegative().optional()});R("state",[f({state:p("ready"),collections:w(hA)}),re]),b({scope:L,focus:Ot.optional(),hops:q([p(1),p(2)]).optional(),query:a().max(Qt).optional()});const fA=f({id:a(),title:a(),aliases:w(a()),findings:d().int().nonnegative(),degree:d().int().nonnegative()}),pA=R("kind",[f({kind:p("claim"),id:a(),from:a(),to:a(),predicate:a(),finding:a(),standing:pe}),f({kind:p("context"),id:a(),from:a(),to:a(),reason:a()})]),Ui=f({concepts:d().int().nonnegative(),connections:d().int().nonnegative()});R("state",[f({state:p("ready"),scope:L,focus:a().nullable(),concepts:w(fA),connections:w(pA),shown:Ui,total:Ui}),re]),b({scope:L,query:a().max(Qt).optional(),page:d().int().min(0).max(1e4).optional()});const mA=f({id:a(),title:a(),aliases:w(a()),explanation:a(),findings:d().int().nonnegative()});R("state",[f({state:p("ready"),scope:L,rows:w(mA),total:d().int().nonnegative(),page:d().int().nonnegative()}),re]);const gA=g(["all","recheck","differing"]);b({scope:L,query:a().max(Qt).optional(),filter:gA.optional(),page:d().int().min(0).max(1e4).optional()});const Wi=f({from:oe,predicate:a(),to:oe}),wA=f({id:a(),statement:a(),basis:g(["observation","inference"]),conditions:a(),about:w(oe),relationship:Wi.nullable(),standing:pe,attention:Oi,sources:d().int().nonnegative(),checks:d().int().nonnegative()});R("state",[f({state:p("ready"),scope:L,rows:w(wA),total:d().int().nonnegative(),page:d().int().nonnegative()}),re]);const Ut=f({id:a(),kind:p("direction"),text:a(),scope:L,scopeName:a(),origin:a(),authority:g(["instruction","advice"]),revision:d().int().positive(),updatedAt:d()});R("state",[f({state:p("ready"),scope:L,rows:w(Ut),total:d().int().nonnegative(),page:d().int().nonnegative()}),re]),b({id:a().min(1).max(64),page:d().int().min(0).max(1e4).optional()});const bA=Ut.extend({retired:S(),createdAt:d(),history:w(f({revision:d().int().positive(),op:g(["publish","revise","retire"]),text:a(),origin:a(),scope:L,evidence:a(),at:d()})),page:d().int().nonnegative(),total:d().int().nonnegative()});R("state",[f({state:p("ready"),direction:bA}),f({state:p("missing")}),re]);const Wt=a().regex(/^(d:)?[a-z0-9][a-z0-9-]{0,63}$/),zi=a().min(1).max(4e3),zt=a().min(1).max(400),Ki=d().int().positive().optional();R("op",[b({op:p("add"),id:Wt.optional(),text:zi,scope:L.optional(),reason:zt}),b({op:p("revise"),id:Wt,text:zi,expectedRevision:Ki,reason:zt}),b({op:p("retire"),id:Wt,expectedRevision:Ki,reason:zt})]),f({op:g(["add","revise","retire"]),direction:Ut}),b({id:Ot,revision:d().int().positive().optional()});const yA=R("kind",[f({kind:p("file"),path:a(),startLine:d().int(),endLine:d().int(),commit:a().nullable(),dirty:S()}),f({kind:p("report"),key:a(),event:d().int()}),f({kind:p("quote"),citation:a()}),f({kind:p("article"),url:a(),title:a(),author:a().nullable(),published:a().nullable(),retrieved:d()})]),Ti=f({id:a(),origin:yA,text:a(),capturedAt:d(),check:f({state:g(["unchanged","changed","missing","unknown","kept"]),detail:a()})}),vA=f({id:a(),revision:d().int().positive(),verdict:g(["supports","contradicts","inconclusive"]),method:a(),conditions:a(),by:a(),at:d(),sources:w(Ti)}),kA=f({revision:d().int().positive(),op:g(["publish","revise","link","retire","restore"]),by:a(),reason:a(),at:d(),title:a()}),IA=f({type:g(["contradicts","supersedes","duplicates"]),reason:a(),other:oe,outgoing:S(),by:a(),at:d()}),xA=f({revision:d().int().positive(),by:a(),task:a().nullable(),purpose:a(),at:d()}),SA=R("kind",[f({kind:p("claim"),id:a(),finding:a(),from:oe,predicate:a(),to:oe,standing:pe}),f({kind:p("context"),id:a(),from:oe,to:oe,reason:a()})]),CA=f({id:a(),scope:L,kind:g(["concept","finding"]),revision:d().int().positive(),current:d().int().positive(),retired:S(),title:a(),aliases:w(a()),explanation:a(),basis:g(["observation","inference"]).nullable(),conditions:a(),about:w(oe),relationship:Wi.nullable(),standing:pe.nullable(),attention:Oi.nullable(),author:a(),createdAt:d(),at:d(),connections:w(SA),findings:w(f({id:a(),statement:a(),standing:pe})),findingsTotal:d().int().nonnegative(),sources:w(Ti),checks:w(vA),revisions:w(kA),olderRevisions:d().int().nonnegative(),relations:w(IA),uses:f({count:d().int().nonnegative(),recent:w(xA)})});R("state",[f({state:p("ready"),entry:CA}),f({state:p("missing")}),re]);const EA="(?<![A-Za-z0-9_-])[cf]-[a-z0-9]{6}(?![A-Za-z0-9_-])",BA=/^[cf]-[a-z0-9]{6}$/;b({ids:w(Ot).min(1).max(32)});const _A=f({id:a(),kind:g(["concept","finding"]),scope:L,title:a(),revision:d().int().positive(),retired:S(),standing:pe.nullable()});R("state",[f({state:p("ready"),refs:w(_A)}),re]),b({task:a().min(1).max(64)});const DA=f({id:a(),kind:g(["concept","finding"]),scope:L,revision:d().int().positive(),title:a(),current:d().int().positive(),currentTitle:a(),retired:S(),standing:pe.nullable(),purpose:a(),at:d()});R("state",[f({state:p("ready"),uses:w(DA),total:d().int().nonnegative()}),re]);const Gi="(?<![A-Za-z0-9_-])[A-Z0-9]{2,4}-[0-9]{1,9}(?![A-Za-z0-9_-])",NA=/^[A-Z0-9]{2,4}-[0-9]{1,9}$/,FA=64;function ZA(e){const t=[];for(const n of e.matchAll(new RegExp(Gi,"g")))if(!t.includes(n[0])&&(t.push(n[0]),t.length===FA))break;return t}const RA=["GET","HEAD","POST","PUT","PATCH","DELETE"],QA={responseMaxBytes:1048576},OA=/^[A-Za-z0-9-]{1,64}$/,UA=["authorization","cookie","host","origin","proxy-authorization","referer","user-agent"],Mi=b({method:g(RA).default("GET"),path:a().min(1).max(2048).regex(/^\/(?![/\\])/,"an absolute path"),query:V(a().min(1).max(256),a().max(2048)).optional(),headers:V(a().regex(OA),a().max(4096)).optional().refine(e=>!e||Object.keys(e).every(t=>!UA.includes(t.toLowerCase())),"a reserved header"),body:a().max(65536).optional()}),WA=["capability_not_granted","method_not_granted","timeout","network","oversized","rate_limited"];R("ok",[f({ok:p(!0),status:d().int().min(100).max(599),headers:V(a(),a()),body:a().max(QA.responseMaxBytes)}),f({ok:p(!1),error:f({code:g(WA),message:a().max(500)})})]),b({pluginId:a().min(2).max(64),alias:a().min(1).max(32),request:Mi});const zA=`function (previous, message) {
  var value = message.value;
  (message.reuse || []).forEach(function (array) {
    var before = array.key === null ? previous : previous[array.key];
    var added = array.key === null ? value : value[array.key];
    var items = array.indices.map(function (index) {
      return index >= 0 ? before[index] : added[-index - 1];
    });
    if (array.key === null) value = items;
    else Object.defineProperty(value, array.key, { value: items, enumerable: true, writable: true, configurable: true });
  });
  return value;
}`,Ji=2,KA=4096,TA=1024,GA=16*1024*1024,MA=4096,JA="app-frame://media/",YA=256,Yi=4096,LA=500,PA=`(function () {
  var VERSION = ${Ji};
  var LABEL_MAX = ${Ft};
  var QUESTIONS_MAX_BYTES = ${tA};
  var WRITTEN_MAX = ${Ei};
  var nextId = 1;
  var pending = {};
  var subscriptions = {};
  var receiveReadValue = ${zA};
  var themeListeners = [];
  var stateListeners = [];
  var storeListeners = [];
  var state = null;
  var birthState = null;
  var stateSeen = false;
  var sized = false;
  var initialized = false;
  var documentId = Date.now().toString(36) + Math.random().toString(36).slice(2);
  var capped = new WeakSet();
  var theme = document.documentElement.getAttribute("data-theme") || "dark";
  var form = { on: false, locked: false, fill: null, filling: false, staged: {}, first: new WeakMap(), last: "", fields: new WeakMap() };
  var KEY_IN_TEXT = new RegExp(${JSON.stringify(`${Gi}|${EA}`)}, "g");
  var UNLINKED = "a, button, summary, label, input, select, option, textarea, script, style, svg, [role=button], [data-inf-action], [data-inf-draft], [contenteditable]";
  var keys = { known: null, rested: null, quiet: null, lit: null };
  var entries = { known: null };
  var caps = { pictures: false, escape: false };
  var held = { element: null, start: null, end: null, direction: null };
  var listen = EventTarget.prototype.addEventListener;
  // A hook in another spelling of the app's code names - Firstmate 3000's
  // data-fm-action, fm-mono - reads as this build's own too, so a card
  // written before the Infinitary rename works here (src/shared/codeNames.ts). Every
  // element is read as it arrives and again as such an attribute changes; the
  // author's own attributes and classes stay as written.
  var OWN = ${JSON.stringify($e)};
  var OTHERS = ${JSON.stringify(Ee.filter(e=>e!==$e))};
  function ownHook(name) {
    for (var i = 0; i < OTHERS.length; i++) {
      var prefix = "data-" + OTHERS[i] + "-";
      if (name.indexOf(prefix) === 0) return "data-" + OWN + "-" + name.slice(prefix.length);
    }
    return null;
  }
  function respell(element, changed) {
    if (!element || element.nodeType !== 1) return;
    var names = changed ? [changed] : Array.prototype.map.call(element.attributes, function (a) { return a.name; });
    names.forEach(function (name) {
      var own = ownHook(name);
      if (!own) return;
      // Written only when it differs: a write records a change even when the
      // value is the same, which would wake this observer again for ever.
      var value = element.getAttribute(name);
      if (value === null) {
        if (element.hasAttribute(own)) element.removeAttribute(own);
      } else if ((changed || !element.hasAttribute(own)) && element.getAttribute(own) !== value) {
        element.setAttribute(own, value);
      }
    });
    if (element.classList && (!changed || changed === "class")) {
      Array.prototype.slice.call(element.classList).forEach(function (token) {
        for (var i = 0; i < OTHERS.length; i++) {
          var mine = OWN + "-" + token.slice(OTHERS[i].length + 1);
          if (token.indexOf(OTHERS[i] + "-") === 0 && !element.classList.contains(mine)) element.classList.add(mine);
        }
      });
    }
  }
  function respellTree(node) {
    if (node.nodeType !== 1) return;
    respell(node);
    if (node.firstElementChild) Array.prototype.forEach.call(node.querySelectorAll("*"), function (child) { respell(child); });
  }
  respellTree(document.documentElement);
  new MutationObserver(function (records) {
    records.forEach(function (record) {
      if (record.type === "attributes") {
        if (record.attributeName === "class" || ownHook(record.attributeName)) respell(record.target, record.attributeName);
      } else {
        Array.prototype.forEach.call(record.addedNodes, respellTree);
      }
    });
  }).observe(document.documentElement, { subtree: true, childList: true, attributes: true });
  var BRIDGE = document.currentScript;
  var SVG_NS = "http://www.w3.org/2000/svg";
  var hold = document.documentElement.hasAttribute("data-inf-held")
    ? { scripts: [], seen: new WeakSet(), timelines: [], watch: null, style: null, form: false, waiting: false }
    : null;
  document.documentElement.removeAttribute("data-inf-held");
  var loaded = false;
  var settling = false;
  window.addEventListener("load", function () { loaded = true; });
  function holdNodes(nodes) {
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (node.nodeType !== 1) continue;
      var found = node.localName === "script" || node.localName === "svg" ? [node] : [];
      if (node.firstElementChild) found = found.concat(Array.prototype.slice.call(node.querySelectorAll("script, svg")));
      found.forEach(function (element) {
        if (element.localName === "svg") {
          if (element.namespaceURI === SVG_NS && !element.ownerSVGElement && !element.animationsPaused()) {
            element.pauseAnimations();
            hold.timelines.push(element);
          }
          return;
        }
        if (element === BRIDGE || hold.seen.has(element)) return;
        hold.seen.add(element);
        hold.scripts.push({ element: element, type: element.getAttribute("type") });
        element.setAttribute("type", "text/inf-held");
      });
    }
  }
  if (hold) {
    hold.watch = new MutationObserver(function (records) {
      records.forEach(function (record) { holdNodes(record.addedNodes); });
    });
    hold.watch.observe(document.documentElement, { childList: true, subtree: true });
    hold.style = document.createElement("style");
    hold.style.textContent = "*, *::before, *::after { animation-play-state: paused !important; }";
    (document.head || document.documentElement).appendChild(hold.style);
  }
  // Released once the markup is read: at the end of DOMContentLoaded, so a
  // listener a released script adds for it is run here, once, and never by
  // the browser as well.
  function activate() {
    if (!hold || hold.waiting) return;
    if (document.readyState === "loading") {
      hold.waiting = true;
      window.addEventListener("DOMContentLoaded", release, { once: true });
      return;
    }
    release();
  }
  function release() {
    if (!hold) return;
    hold.watch.takeRecords().forEach(function (record) { holdNodes(record.addedNodes); });
    hold.watch.disconnect();
    var parts = hold;
    hold = null;
    parts.style.remove();
    parts.timelines.forEach(function (svg) { svg.unpauseAnimations(); });
    var late = { document: [], window: [], load: [] };
    var shims = [document, window].map(function (target) {
      var shim = function (type, listener, options) {
        if (listener && this === target) {
          if (type === "DOMContentLoaded") late[target === document ? "document" : "window"].push(listener);
          else if (type === "load" && target === window && loaded) late.load.push(listener);
        }
        return listen.call(this, type, listener, options);
      };
      target.addEventListener = shim;
      return { target: target, shim: shim };
    });
    var onload = window.onload;
    parts.scripts.forEach(function (entry) {
      var old = entry.element;
      if (!old.isConnected) return;
      var script = document.createElementNS(old.namespaceURI, "script");
      for (var i = 0; i < old.attributes.length; i++) {
        var attribute = old.attributes[i];
        if (attribute.name !== "type") script.setAttributeNS(attribute.namespaceURI, attribute.name, attribute.value);
      }
      if (entry.type !== null) script.setAttribute("type", entry.type);
      script.textContent = old.textContent;
      old.replaceWith(script);
    });
    shims.forEach(function (entry) {
      if (entry.target.addEventListener === entry.shim) delete entry.target.addEventListener;
    });
    var target = { document: document, window: window, load: window };
    ["document", "window", "load"].forEach(function (phase) {
      late[phase].forEach(function (listener) {
        var event = new Event(phase === "load" ? "load" : "DOMContentLoaded");
        try {
          if (typeof listener === "function") listener.call(target[phase], event);
          else if (typeof listener.handleEvent === "function") listener.handleEvent(event);
        } catch (error) {
          reportError(error);
        }
      });
    });
    if (loaded && window.onload !== onload && typeof window.onload === "function") {
      try { window.onload(new Event("load")); } catch (error) { reportError(error); }
    }
    // The form's baseline is what the body shows once its scripts have run.
    if (parts.form) startForm();
    // What the scripts do in their first two frames is the drawing settling, not a live change.
    settling = true;
    requestAnimationFrame(function () { requestAnimationFrame(function () { settling = false; }); });
    reportDrawing();
  }
  function capFigures() {
    if (!sized) return;
    var figures = document.querySelectorAll('svg[width="100%"]');
    for (var i = 0; i < figures.length; i++) {
      var figure = figures[i];
      if (figure.parentElement && figure.parentElement.closest("svg")) continue;
      if (figure.style.maxWidth && !capped.has(figure)) continue;
      var box = figure.viewBox && figure.viewBox.baseVal;
      if (!box || !(box.width > 0)) continue;
      var cap = box.width + "px";
      if (figure.style.maxWidth !== cap) figure.style.maxWidth = cap;
      capped.add(figure);
    }
  }
  // Resolves at a frame on which no font face is still loading: a face
  // still loading is awaited, and the next frame looks again.
  function fontsIn() {
    return new Promise(function (resolve) {
      requestAnimationFrame(function look() {
        var loading = [];
        document.fonts.forEach(function (face) {
          if (face.status === "loading") loading.push(face.loaded.then(null, function () {}));
        });
        if (!loading.length) { resolve(); return; }
        Promise.all(loading).then(function () { requestAnimationFrame(look); });
      });
    });
  }
  function post(message) {
    message.fm = VERSION;
    message.document = documentId;
    parent.postMessage(message, "*");
  }
  var pendingMarkup;
  function refreshMarkup(html) {
    // The initial refresh can arrive before the original parser finishes.
    // Let it finish before morphing, including when no body exists yet.
    if (document.readyState === "loading") {
      pendingMarkup = html;
      return;
    }
    pendingMarkup = undefined;
    if (!document.body) return;
    var next = document.createElement("template");
    next.innerHTML = html;
    morphChildren(document.body, next.content);
  }
  document.addEventListener("DOMContentLoaded", function () {
    if (pendingMarkup === undefined) return;
    var html = pendingMarkup;
    pendingMarkup = undefined;
    refreshMarkup(html);
  }, { once: true });
  function blank(node) {
    return node.nodeType === 3 && node.nodeValue.trim() === "";
  }
  function morphChildren(into, from) {
    var at = into.firstChild;
    var source = from.firstChild;
    while (source) {
      var following = source.nextSibling;
      if (!at) {
        into.appendChild(source);
      } else if (at.nodeType === source.nodeType && at.nodeName === source.nodeName) {
        if (at.nodeType === 1) {
          morphAttributes(at, source);
          morphChildren(at, source);
        } else if (at.nodeValue !== source.nodeValue) {
          at.nodeValue = source.nodeValue;
        }
        at = at.nextSibling;
      } else if (blank(at)) {
        // Whitespace the document was written with goes, and the same
        // source meets the next node: the markup around it is not new.
        var gone = at;
        at = at.nextSibling;
        into.removeChild(gone);
        continue;
      } else if (blank(source)) {
        into.insertBefore(source, at);
      } else {
        var replaced = at;
        at = at.nextSibling;
        into.replaceChild(source, replaced);
      }
      source = following;
    }
    while (at) {
      var rest = at.nextSibling;
      into.removeChild(at);
      at = rest;
    }
  }
  function morphAttributes(element, source) {
    var i;
    for (i = element.attributes.length - 1; i >= 0; i--) {
      var name = element.attributes[i].name;
      // A reader owns a keyed disclosure's open state through live refreshes.
      // A new identity (for example a changed version or evidence) resets it.
      if (name === "open" && element.tagName === "DETAILS" &&
          element.hasAttribute("data-inf-disclosure") &&
          element.getAttribute("data-inf-disclosure") === source.getAttribute("data-inf-disclosure")) continue;
      if (!source.hasAttribute(name)) element.removeAttribute(name);
    }
    for (i = 0; i < source.attributes.length; i++) {
      var attribute = source.attributes[i];
      if (element.getAttribute(attribute.name) !== attribute.value) element.setAttribute(attribute.name, attribute.value);
    }
  }
  function bridgeError(code, message) {
    var error = new Error(message);
    error.name = "FrameBridgeError";
    error.code = code;
    return error;
  }
  function request(verb, payload) {
    return new Promise(function (resolve, reject) {
      var id = nextId++;
      pending[id] = { resolve: resolve, reject: reject };
      var message = { type: "request", id: id, verb: verb };
      for (var key in payload) message[key] = payload[key];
      post(message);
    });
  }
  window.addEventListener("message", function (event) {
    if (event.source !== parent) return;
    var data = event.data;
    if (!data || data.fm !== VERSION || typeof data.type !== "string") return;
    if (data.type === "initialize") {
      if (data.document !== documentId) return;
      var born = document.readyState === "loading"
        ? new Promise(function (resolve) { document.addEventListener("DOMContentLoaded", resolve, { once: true }); })
        : Promise.resolve();
      // A host whose pictures can arrive long after the body (a phone's
      // come over its connection) has the drawing wait only for the fonts
      // its layout asked for: WebKit resolves document.fonts.ready only
      // after the page's load event, which waits for every picture
      // (INF-1562).
      var latePictures = data.latePictures === true;
      born.then(function () {
        capFigures();
        if (document.body) document.body.getBoundingClientRect();
        return latePictures ? fontsIn() : document.fonts.ready;
      }).then(function () {
        requestAnimationFrame(function () { requestAnimationFrame(function () {
          initialized = true;
          resize();
        }); });
      });
    } else if (data.type === "response") {
      if (data.document !== documentId) return;
      var waiter = pending[data.id];
      if (!waiter) return;
      delete pending[data.id];
      if (data.ok) waiter.resolve(data.result);
      else waiter.reject(bridgeError(data.error.code, data.error.message));
    } else if (data.type === "data") {
      var subscription = subscriptions[data.sub];
      if (!subscription) return;
      if (data.error) {
        if (subscription.onError) subscription.onError(bridgeError(data.error.code, data.error.message));
      } else {
        subscription.value = receiveReadValue(subscription.value, data);
        subscription.onValue(subscription.value);
      }
    } else if (data.type === "ping") {
      post({ type: "pong", seq: data.seq });
    } else if (data.type === "state") {
      if (!stateSeen) {
        stateSeen = true;
        birthState = data.state;
      }
      state = data.state;
      stateListeners.slice().forEach(function (listener) { listener(state); });
    } else if (data.type === "store") {
      storeListeners.slice().forEach(function (listener) { listener(data.key); });
    } else if (data.type === "form") {
      form.fill = Array.isArray(data.fill) ? data.fill : null;
      form.locked = data.readOnly === true;
      if (hold) hold.form = true;
      else if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", startForm);
      else startForm();
    } else if (data.type === "tasks") {
      var known = {};
      var any = false;
      (Array.isArray(data.keys) ? data.keys : []).forEach(function (key) {
        if (typeof key === "string") { known[key] = true; any = true; }
      });
      keys.known = any ? known : null;
      if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", linkKeys, { once: true });
      else linkKeys();
    } else if (data.type === "lit") {
      keys.lit = typeof data.key === "string" ? data.key : null;
      markLit();
    } else if (data.type === "entries") {
      var named = {};
      var some = false;
      (Array.isArray(data.entries) ? data.entries : []).forEach(function (entry) {
        if (entry && typeof entry.id === "string" && typeof entry.label === "string") {
          named[entry.id] = { label: entry.label, tone: entry.tone === "ok" || entry.tone === "warn" ? entry.tone : "none" };
          some = true;
        }
      });
      entries.known = some ? named : null;
      if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", linkKeys, { once: true });
      else {
        refreshEntries();
        linkKeys();
      }
    } else if (data.type === "keys") {
      caps.pictures = data.pictures === true;
      caps.escape = data.escape === true;
      if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", tagPictures, { once: true });
      else tagPictures();
    } else if (data.type === "focus") {
      returnFocus();
    } else if (data.type === "reveal") {
      if (data.document !== documentId || !Number.isSafeInteger(data.seq) || !Number.isSafeInteger(data.start)) return;
      var stamp = document.querySelector("[data-inf-revision-offer]");
      if (!stamp || stamp.getAttribute("data-inf-revision-offer") !== data.offerId) return;
      var targets = document.querySelectorAll('[data-inf-target="' + data.start + '"]');
      var target = targets.length === 1 ? targets[0] : null;
      if (!target) { post({ type: "revealed", seq: data.seq, offerId: data.offerId }); return; }
      var ancestor = target.parentElement;
      while (ancestor) { if (ancestor.tagName === "DETAILS") ancestor.open = true; ancestor = ancestor.parentElement; }
      resize();
      requestAnimationFrame(function () {
        if (!target.isConnected) { post({type: "revealed", seq: data.seq, offerId: data.offerId}); return; }
        var rect = target.getBoundingClientRect();
        if (!target.getClientRects().length) { post({type: "revealed", seq: data.seq, offerId: data.offerId}); return; }
        document.querySelectorAll("[data-inf-revision-highlight]").forEach(function (el) { el.removeAttribute("data-inf-revision-highlight"); });
        target.setAttribute("data-inf-revision-highlight", "");
        setTimeout(function () { target.removeAttribute("data-inf-revision-highlight"); }, 1000);
        if (data.keyboard) { if (!target.hasAttribute("tabindex")) target.setAttribute("tabindex", "-1"); target.focus({preventScroll: true}); }
        post({ type: "revealed", seq: data.seq, offerId: data.offerId, top: rect.top + window.scrollY, height: rect.height });
      });
    } else if (data.type === "collect") {
      readForm(data.seq);
      if (data.focusUnpicked) focusUnpicked();
    } else if (data.type === "width") {
      sized = true;
      document.documentElement.setAttribute("data-width", String(data.width));
      capFigures();
    } else if (data.type === "inset") {
      // The box the card's chrome holds over this document's top right: the
      // stylesheet's [data-inf-inset] spacer keeps the first lines clear of it.
      var box = document.documentElement.style;
      box.setProperty("--inf-inset-width", Math.max(0, Number(data.width) || 0) + "px");
      box.setProperty("--inf-inset-height", Math.max(0, Number(data.height) || 0) + "px");
    } else if (data.type === "activate") {
      activate();
    } else if (data.type === "markup") {
      if (typeof data.html === "string") refreshMarkup(data.html);
    } else if (data.type === "theme") {
      theme = data.theme;
      document.documentElement.setAttribute("data-theme", theme);
      if (document.body) document.body.setAttribute("data-theme", theme);
      themeListeners.slice().forEach(function (listener) { listener(theme); });
    }
  });
  var fm = {
    version: VERSION,
    get theme() { return theme; },
    get state() { return state; },
    get birthState() { return birthState; },
    onTheme: function (listener) {
      themeListeners.push(listener);
      return function () {
        themeListeners = themeListeners.filter(function (l) { return l !== listener; });
      };
    },
    onState: function (listener) {
      stateListeners.push(listener);
      return function () {
        stateListeners = stateListeners.filter(function (l) { return l !== listener; });
      };
    },
    subscribe: function (read, args, onValue, onError) {
      var sub = nextId++;
      subscriptions[sub] = { onValue: onValue, onError: onError };
      var ready = request("subscribe", { sub: sub, read: read, args: args === undefined ? {} : args });
      ready.catch(function () { delete subscriptions[sub]; });
      return {
        ready: ready,
        unsubscribe: function () {
          if (!subscriptions[sub]) return Promise.resolve();
          delete subscriptions[sub];
          return request("unsubscribe", { sub: sub });
        }
      };
    },
    action: function (id, value) {
      return request("action", value === undefined ? { action: String(id) } : { action: String(id), value: value });
    },
    fetch: function (alias, req) {
      return request("fetch", { alias: String(alias), request: req });
    },
    store: function (req) {
      return request("store", req);
    },
    onStore: function (listener) {
      storeListeners.push(listener);
      return function () {
        storeListeners = storeListeners.filter(function (l) { return l !== listener; });
      };
    },
    stage: function (name, value) {
      var json = value === undefined ? undefined : JSON.stringify(value);
      if (json === undefined) delete form.staged[String(name)];
      else form.staged[String(name)] = json;
      if (form.on) readForm();
    }
  };
  Object.freeze(fm);
  // The same bridge under every spelling's name: window.inf, and window.fm
  // for a body written before the Infinitary rename.
  ${Ee.map(e=>`window.${e} = fm;`).join(" ")}
  ${Ee.map(e=>`window.${e}Action = function (id) { fm.action(id).catch(function () {}); };`).join(" ")}
  var STRIP_SHOWN = 6;
  function groupPictures(group) {
    var pictures = [];
    for (var i = 0; i < group.children.length; i++) {
      if (group.children[i].tagName === "IMG") pictures.push(group.children[i]);
    }
    return pictures;
  }
  function showPictures(pictures, index) {
    post({
      type: "image",
      index: index,
      pictures: pictures.map(function (picture) {
        return {
          src: picture.currentSrc || picture.src,
          alt: picture.getAttribute("alt") || "",
          width: picture.naturalWidth || 0,
          height: picture.naturalHeight || 0
        };
      })
    });
  }
  function openPicture(picture) {
    var demo = demoOf(picture.closest("figure[data-inf-demo]"));
    if (demo && demo.poster === picture) {
      showDemo(demo, false);
      return;
    }
    var group = picture.closest(".inf-pictures");
    var members = group ? groupPictures(group) : [];
    var index = members.indexOf(picture);
    if (index < 0) {
      members = [picture];
      index = 0;
    }
    showPictures(members, index);
  }
  var DEMO_SOURCE = ${JSON.stringify(JA)};
  var DEMO_CAPTION_MAX = ${Yi};
  function demoOf(figure) {
    if (!figure || !figure.hasAttribute("data-inf-demo")) return null;
    var src = figure.getAttribute("data-inf-demo") || "";
    var poster = figure.querySelector("img");
    if (src.indexOf(DEMO_SOURCE) !== 0 || !poster) return null;
    return { figure: figure, src: src, poster: poster };
  }
  function demoMs(figure) {
    var ms = Math.round(Number(figure.getAttribute("data-inf-demo-duration")));
    return ms > 0 && ms < 600000 ? ms : 0;
  }
  function showDemo(demo, play) {
    var caption = demo.figure.querySelector("figcaption");
    var poster = demo.poster;
    post({
      type: "demo",
      src: demo.src,
      play: play,
      durationMs: demoMs(demo.figure),
      caption: caption ? (caption.textContent || "").replace(/\\s+/g, " ").trim().slice(0, DEMO_CAPTION_MAX) : "",
      poster: {
        src: poster.currentSrc || poster.src,
        alt: poster.getAttribute("alt") || "",
        width: poster.naturalWidth || 0,
        height: poster.naturalHeight || 0
      }
    });
  }
  // Each verified demo gets its Play button, with the recording's length,
  // under its poster: drawn with the body, so it is part of its first drawing.
  // A figure is done only once it has its button: the parser can pause after
  // the figure's start tag, before its poster, and the next change draws it.
  function decorateDemos() {
    if (!document.body) return false;
    var figures = document.querySelectorAll("figure[data-inf-demo]:not([data-inf-demo-ready])");
    var drawn = false;
    for (var i = 0; i < figures.length; i++) {
      var demo = demoOf(figures[i]);
      if (!demo) continue;
      figures[i].setAttribute("data-inf-demo-ready", "");
      var seconds = Math.max(1, Math.round(demoMs(demo.figure) / 1000));
      var button = document.createElement("button");
      button.type = "button";
      button.setAttribute("data-inf-demo-play", "");
      button.setAttribute("aria-label", "Play the demo, " + seconds + (seconds === 1 ? " second" : " seconds"));
      button.textContent = "Play · " + seconds + " s";
      demo.poster.insertAdjacentElement("afterend", button);
      drawn = true;
    }
    return drawn;
  }
  var PICTURE_CONTROL = "a, button, summary, label, [data-inf-action]";
  var UNSHOWN_PICTURE = ".inf-pictures > img:nth-of-type(n+7)";
  function tagPictures() {
    if (!caps.pictures || !document.body) return;
    var pictures = document.querySelectorAll("img:not([data-inf-picture]):not([tabindex])");
    var tagged = false;
    for (var i = 0; i < pictures.length; i++) {
      var picture = pictures[i];
      if (picture.closest(PICTURE_CONTROL) || picture.matches(UNSHOWN_PICTURE)) continue;
      picture.setAttribute("data-inf-picture", "");
      picture.setAttribute("tabindex", "0");
      tagged = true;
    }
    if (!tagged) return;
    // The same pictures in the same place: a stop for the keyboard is not the body changing.
    sizeWatch.takeRecords();
  }
  function moreTileIndex(group, x, y) {
    var pictures = groupPictures(group);
    if (pictures.length <= STRIP_SHOWN) return -1;
    var tile = getComputedStyle(group, "::after");
    if (tile.content === "none" || tile.display === "none") return -1;
    var last = pictures[STRIP_SHOWN - 1];
    var lastBox = last.getBoundingClientRect();
    var box = group.getBoundingClientRect();
    var width = parseFloat(tile.width) || 0;
    var height = parseFloat(tile.height) || 0;
    var left = lastBox.right + (parseFloat(getComputedStyle(group).columnGap) || 0);
    var top = lastBox.top;
    if (left + width > box.right + 0.5) {
      left = box.left;
      top = lastBox.bottom + (parseFloat(getComputedStyle(last).marginBottom) || 0);
    }
    return x >= left && x <= left + width && y >= top && y <= top + height ? STRIP_SHOWN : -1;
  }
  document.addEventListener("click", function (event) {
    var target = event.target;
    var action = target && target.closest ? target.closest("[data-inf-action]") : null;
    if (action) {
      event.preventDefault();
      window.infAction(action.getAttribute("data-inf-action"));
      return;
    }
    var draft = target && target.closest ? target.closest("[data-inf-draft]") : null;
    if (draft) {
      event.preventDefault();
      post({ type: "draft", text: draft.getAttribute("data-inf-draft") });
      return;
    }
    var task = keyLink(target);
    if (task) {
      event.preventDefault();
      openKey(task);
      return;
    }
    var reference = entryLink(target);
    if (reference) {
      event.preventDefault();
      openEntry(reference);
      return;
    }
    var link = target && target.closest ? target.closest("a[href]") : null;
    if (link) {
      event.preventDefault();
      post({ type: "link", href: link.getAttribute("href") });
      return;
    }
    if (event.defaultPrevented || !target || !target.closest) return;
    var play = target.closest("[data-inf-demo-play]");
    if (play) {
      var playing = demoOf(play.closest("figure[data-inf-demo]"));
      if (playing) showDemo(playing, true);
      return;
    }
    var picture = target.closest("img");
    if (picture) {
      if (picture.closest("button, summary, label")) return;
      openPicture(picture);
      return;
    }
    if (target.classList.contains("inf-pictures")) {
      var more = moreTileIndex(target, event.clientX, event.clientY);
      if (more >= 0) showPictures(groupPictures(target), more);
    }
  });
  function kindOf(control) {
    if (control.tagName === "SELECT") return "select";
    if (control.tagName === "TEXTAREA") return "text";
    var type = (control.getAttribute("type") || "text").toLowerCase();
    if (type === "radio" || type === "checkbox" || type === "hidden") return type;
    if (type === "submit" || type === "button" || type === "reset" || type === "image" || type === "file") return "";
    return "text";
  }
  function words(node) {
    return (node.textContent || "").replace(/\\s+/g, " ").trim().slice(0, 500);
  }
  function labelOf(control) {
    var parts = [];
    for (var i = 0; control.labels && i < control.labels.length; i++) parts.push(words(control.labels[i]));
    return parts.join(" ").trim();
  }
  function questions() {
    var list = [];
    var byName = {};
    var controls = document.querySelectorAll("input[name], select[name], textarea[name]");
    for (var i = 0; i < controls.length; i++) {
      var control = controls[i];
      var kind = kindOf(control);
      if (!kind || control.disabled || !control.name) continue;
      if (kind === "hidden" && !form.first.has(control)) form.first.set(control, control.value);
      var group = byName[control.name];
      if (!group) {
        group = byName[control.name] = { name: control.name, controls: [], required: false };
        list.push(group);
      }
      group.controls.push(control);
      if (control.required) group.required = true;
    }
    for (var name in form.staged) {
      if (!byName[name]) {
        byName[name] = { name: name, controls: [], required: false };
        list.push(byName[name]);
      }
      byName[name].staged = true;
    }
    return list;
  }
  function recommended(control, fallback) {
    var owner = control.tagName === "OPTION" ? control.closest("select") : control;
    var marked = owner.tagName === "SELECT"
      ? owner.querySelector("option[data-inf-recommended]")
      : document.querySelector('input[name="' + CSS.escape(control.name) + '"][data-inf-recommended]');
    return marked ? control.hasAttribute("data-inf-recommended") : fallback;
  }
  // A question's Something else row (FI3-1002): the author writes it as one
  // more radio or checkbox of the question, or an <option> of its select,
  // marked data-inf-write-in. It is never an option value: once picked the
  // app opens a text field under it, and the words in it are the answer.
  function isWriteIn(control) {
    return control.hasAttribute("data-inf-write-in");
  }
  function rowPicked(row) {
    return row.tagName === "OPTION" ? row.selected : row.checked;
  }
  function writeInRows(group) {
    var rows = [];
    group.controls.forEach(function (control) {
      var kind = kindOf(control);
      if ((kind === "radio" || kind === "checkbox") && isWriteIn(control)) rows.push(control);
      else if (kind === "select") {
        for (var i = 0; i < control.options.length; i++) if (isWriteIn(control.options[i])) rows.push(control.options[i]);
      }
    });
    return rows;
  }
  function pickedWriteIn(group) {
    return writeInRows(group).find(rowPicked) || null;
  }
  function writtenOf(row) {
    var field = row && form.fields.get(row);
    return field && rowPicked(row) ? field.value.trim().slice(0, WRITTEN_MAX) : "";
  }
  function hasAnswer(answer) {
    return answer.values.length > 0 || answer.written !== undefined;
  }
  function focusUnpicked() {
    var group = questions().find(function (group) { return group.required && !hasAnswer(answerOf(group)); });
    if (!group) return;
    // A picked Something else with nothing written: its field is what waits.
    var field = form.fields.get(pickedWriteIn(group));
    var control = field && !field.hidden ? field : group.controls.find(function (control) { return !control.disabled && !boxless(control); });
    if (control) { control.focus(); control.scrollIntoView({ block: "center", behavior: "smooth" }); }
  }
  // A question that recommends rather than pre-picks: nothing is chosen
  // until the captain chooses, so any answer it has is the captain's pick.
  function tagged(group) {
    return group.controls.some(function (control) { return control.hasAttribute("data-inf-recommended") || (kindOf(control) === "select" && control.querySelector("option[data-inf-recommended]")); });
  }
  function answerOf(group) {
    if (group.staged) return { name: group.name, values: [form.staged[group.name]], changed: true, json: true };
    var values = [];
    var labels = [];
    var proposed = [];
    function pick(value, label) {
      if (value === "") return;
      values.push(value);
      labels.push(label);
    }
    group.controls.forEach(function (control) {
      var kind = kindOf(control);
      if (kind === "radio" || kind === "checkbox") {
        if (isWriteIn(control)) return;
        if (control.checked) pick(control.value, labelOf(control));
        if (recommended(control, control.defaultChecked) && control.value !== "") proposed.push(control.value);
      } else if (kind === "select") {
        var marked = false;
        for (var i = 0; i < control.options.length; i++) {
          var option = control.options[i];
          if (isWriteIn(option)) continue;
          if (option.selected) pick(option.value, words(option));
          if (recommended(option, option.defaultSelected)) {
            marked = true;
            if (option.value !== "") proposed.push(option.value);
          }
        }
        var first = control.options[0];
        if (!marked && !control.multiple && first && first.value !== "" && !isWriteIn(first)) proposed.push(first.value);
      } else {
        pick(control.value, "");
        var initial = kind === "hidden" ? form.first.get(control) : control.defaultValue;
        if (initial) proposed.push(initial);
      }
    });
    // The captain's own words are never what the author proposed.
    var written = writtenOf(pickedWriteIn(group));
    var changed = written !== "" || ((!tagged(group) || values.length > 0) && JSON.stringify(values.slice().sort()) !== JSON.stringify(proposed.sort()));
    var answer = { name: group.name, values: values, changed: changed };
    if (labels.some(function (label) { return label !== ""; })) answer.labels = labels;
    if (written) answer.written = written;
    return answer;
  }
  function wording(text) {
    var whole = (text || "").replace(/\\s+/g, " ").trim();
    return { text: whole.slice(0, LABEL_MAX), cut: whole.length > LABEL_MAX };
  }
  // A node's own words: the text of a control it wraps - a select's
  // options, a textarea's default - is an answer, never the question.
  function spoken(node) {
    var copy = node.cloneNode(true);
    var inner = copy.querySelectorAll("select, textarea, script, style");
    for (var i = 0; i < inner.length; i++) inner[i].remove();
    return copy.textContent || "";
  }
  function byIds(ids) {
    var parts = [];
    (ids || "").split(/\\s+/).forEach(function (id) {
      var node = id ? document.getElementById(id) : null;
      if (node) parts.push(spoken(node));
    });
    return parts.join(" ");
  }
  function ownWording(node) {
    if (node.hasAttribute("aria-labelledby")) return { raw: byIds(node.getAttribute("aria-labelledby")), basis: "labelledby" };
    if (node.hasAttribute("aria-label")) return { raw: node.getAttribute("aria-label"), basis: "aria-label" };
    if (node.tagName === "FIELDSET") {
      for (var i = 0; i < node.children.length; i++) {
        if (node.children[i].tagName === "LEGEND") return { raw: spoken(node.children[i]), basis: "legend" };
      }
    }
    return null;
  }
  function holderOf(control) {
    for (var node = control.parentElement; node && node !== document.body; node = node.parentElement) {
      var role = node.getAttribute("role");
      if (node.tagName === "FIELDSET" || role === "group" || role === "radiogroup") return node;
    }
    return null;
  }
  function promptOf(controls, lone) {
    if (lone) {
      var own = ownWording(controls[0]);
      if (own && own.raw) return own;
      var bound = [];
      for (var i = 0; controls[0].labels && i < controls[0].labels.length; i++) bound.push(spoken(controls[0].labels[i]));
      if (bound.join("").trim()) return { raw: bound.join(" "), basis: "label" };
    }
    var holders = controls.map(holderOf);
    var holder = holders[0];
    if (holders.every(function (each) { return each === holder; })) {
      if (holder) return ownWording(holder) || { gap: "no-prompt" };
    } else if (holders.some(function (each) { return each; })) return { gap: "conflicting-prompt" };
    var first = controls.map(function (control) { return (control.getAttribute("aria-labelledby") || "").split(/\\s+/)[0]; });
    if (!lone && first[0] && first.every(function (id) { return id === first[0]; })) return { raw: byIds(first[0]), basis: "labelledby" };
    return { gap: "no-prompt" };
  }
  function boxless(node) {
    return node.hidden || node.getClientRects().length === 0;
  }
  function defineQuestion(group) {
    var gaps = [];
    function gap(name) { if (gaps.indexOf(name) < 0) gaps.push(name); }
    function label(text) {
      var read = wording(text);
      if (read.cut) gap("label-truncated");
      return read.text || null;
    }
    var definition = { name: group.name, kind: "opaque", control: "staged", prompt: null, promptBasis: null, options: [], defaultBasis: "none", required: group.required, gaps: gaps, complete: false };
    if (group.staged) {
      gap("opaque");
      return definition;
    }
    var all = [];
    var named = document.getElementsByName(group.name);
    for (var i = 0; i < named.length; i++) if (kindOf(named[i])) all.push(named[i]);
    var kinds = [];
    group.controls.forEach(function (control) {
      var kind = kindOf(control);
      if (kinds.indexOf(kind) < 0) kinds.push(kind);
    });
    var kind = kinds.length === 1 ? kinds[0] : "mixed";
    var first = group.controls[0];
    if (kind === "mixed") {
      gap("mixed-controls");
      definition.control = "mixed";
    } else if (kind === "hidden") {
      definition.control = "hidden";
      if (form.first.get(first)) definition.defaultBasis = "authored";
    } else if (kind === "radio" || kind === "checkbox") {
      definition.control = kind;
      definition.kind = kind === "radio" ? "single" : "multiple";
      all.forEach(function (control) {
        if (kindOf(control) !== kind) return;
        if (isWriteIn(control)) {
          definition.writeIn = true;
          return;
        }
        definition.options.push({ value: control.value, label: label(labelOf(control)), authoredDefault: recommended(control, control.defaultChecked), disabled: control.disabled, hidden: boxless(control) });
      });
      if (definition.options.some(function (option) { return option.authoredDefault; })) definition.defaultBasis = "authored";
    } else if (kind === "select") {
      definition.control = first.multiple ? "select-multiple" : "select";
      definition.kind = first.multiple ? "multiple" : "single";
      group.controls.forEach(function (control) {
        for (var i = 0; i < control.options.length; i++) {
          var option = control.options[i];
          if (isWriteIn(option)) {
            definition.writeIn = true;
            continue;
          }
          definition.options.push({ value: option.value, label: label(option.textContent), authoredDefault: recommended(option, option.defaultSelected), disabled: option.disabled, hidden: option.hidden });
        }
      });
      if (definition.options.some(function (option) { return option.authoredDefault; })) definition.defaultBasis = "authored";
      else if (!first.multiple && first.options[0] && first.options[0].value !== "") definition.defaultBasis = "implicit-first";
    } else {
      definition.control = first.tagName === "TEXTAREA" ? "textarea" : "text";
      definition.kind = "text";
      if (group.controls.some(function (control) { return control.defaultValue; })) definition.defaultBasis = "authored";
    }
    if (definition.kind === "opaque") {
      gap("opaque");
      return definition;
    }
    var values = definition.options.map(function (option) { return option.value; });
    if (values.some(function (value, index) { return values.indexOf(value) !== index; })) gap("duplicate-values");
    var lone = group.controls.length === 1 && (kind === "text" || kind === "select");
    var prompt = promptOf(group.controls, lone);
    if (prompt.gap || !wording(prompt.raw).text) gap(prompt.gap || "no-prompt");
    else {
      definition.prompt = label(prompt.raw);
      definition.promptBasis = prompt.basis;
    }
    definition.complete = gaps.length === 0;
    return definition;
  }
  function readForm(seq) {
    var answers = [];
    var answered = 0;
    var changed = 0;
    var picked = 0;
    var groups = questions();
    groups.forEach(function (group) {
      var answer = answerOf(group);
      answers.push(answer);
      if (!group.required || hasAnswer(answer)) answered += 1;
      if (answer.changed) changed += 1;
      // The captain's own answers, which a close would lose: a change from
      // the author's proposal, a pick where the author only recommended, or
      // words written under Something else. An untouched prefilled field or
      // authored default is not one.
      if (tagged(group) ? hasAnswer(answer) : answer.changed) picked += 1;
    });
    var message = { type: "answers", answered: answered, of: answers.length, changed: changed, picked: picked, answers: answers };
    var key = JSON.stringify(message);
    if (seq === undefined && key === form.last) return;
    form.last = key;
    if (seq !== undefined) {
      message.seq = seq;
      // What the questions offered rides only the reading a footer click
      // asked for, never a draft (docs/card-evidence.md).
      try {
        var defined = groups.map(defineQuestion);
        if (new TextEncoder().encode(JSON.stringify(defined)).byteLength > QUESTIONS_MAX_BYTES) message.questionsGap = "too-large";
        else message.questions = defined;
      } catch (error) {
        message.questionsGap = "invalid";
      }
    }
    post(message);
  }
  function fillForm(answers) {
    var byName = {};
    questions().forEach(function (group) { byName[group.name] = group; });
    var touched = [];
    answers.forEach(function (answer) {
      if (!answer || !Array.isArray(answer.values)) return;
      if (answer.json) {
        if (typeof answer.values[0] === "string") form.staged[answer.name] = answer.values[0];
        return;
      }
      var group = byName[answer.name];
      if (!group || group.staged) return;
      if (!answer.changed && group.controls.every(function (control) { var kind = kindOf(control); return kind === "text" || kind === "hidden"; })) return;
      var values = answer.values.map(String);
      // Words written under Something else come back under the new body's
      // own Something else row; a body with none leaves them at its proposal.
      var written = typeof answer.written === "string" ? answer.written : "";
      var row = written ? writeInRows(group)[0] || null : null;
      if (written && !row && values.length === 0) return;
      var offered = group.controls.some(function (control) {
        var kind = kindOf(control);
        if (kind === "text" || kind === "hidden") return true;
        if (kind !== "select") return values.indexOf(control.value) >= 0;
        for (var i = 0; i < control.options.length; i++) {
          if (values.indexOf(control.options[i].value) >= 0) return true;
        }
        return false;
      });
      if (values.length > 0 && !offered) return;
      var next = 0;
      group.controls.forEach(function (control) {
        var kind = kindOf(control);
        if (kind === "radio" || kind === "checkbox") control.checked = isWriteIn(control) ? control === row : values.indexOf(control.value) >= 0;
        else if (kind === "select") {
          for (var i = 0; i < control.options.length; i++) {
            var option = control.options[i];
            option.selected = isWriteIn(option) ? option === row : values.indexOf(option.value) >= 0;
          }
        } else control.value = values[next++] || "";
        touched.push(control);
      });
      var field = row && writeInField(row);
      if (field) field.value = written;
    });
    form.filling = true;
    try {
      touched.forEach(function (control) {
        control.dispatchEvent(new Event("input", { bubbles: true }));
        control.dispatchEvent(new Event("change", { bubbles: true }));
      });
    } finally {
      form.filling = false;
    }
  }
  function tagRecommendations() {
    document.querySelectorAll("input[data-inf-recommended]:is([type=radio], [type=checkbox])").forEach(function (control) {
      Array.from(control.labels || []).forEach(function (label) { if (!label.hasAttribute("data-inf-recommended-label")) label.setAttribute("data-inf-recommended-label", ""); });
    });
    document.querySelectorAll("select").forEach(function (select) {
      var options = Array.from(select.options).filter(function (option) { return option.hasAttribute("data-inf-recommended"); });
      var tag = select.nextElementSibling;
      if (!tag || !tag.hasAttribute("data-inf-recommendation")) {
        if (!options.length) return;
        tag = document.createElement("span");
        tag.setAttribute("data-inf-recommendation", "");
        select.after(tag);
      }
      var text = options.length ? "Recommended: " + options.map(words).join(", ") : "";
      if (tag.textContent !== text) tag.textContent = text;
    });
  }
  // The field under a Something else row: the app's own, with no name, so
  // its words ride the row's question as "written" and never a question of
  // their own. One line that grows to three (the frame stylesheet).
  function writeInField(row) {
    var field = form.fields.get(row);
    if (field && field.isConnected) return field;
    var owner = row.tagName === "OPTION" ? row.closest("select") : row;
    if (!owner || !owner.name) return null;
    field = document.createElement("textarea");
    field.setAttribute("data-inf-write-in-field", owner === row ? "row" : "select");
    field.rows = 1;
    field.maxLength = WRITTEN_MAX;
    field.placeholder = "Say what you want instead";
    var named = [];
    var all = document.getElementsByName(owner.name);
    for (var i = 0; i < all.length; i++) if (kindOf(all[i])) named.push(all[i]);
    var asked = promptOf(named, owner !== row);
    var prompt = asked.gap ? "" : wording(asked.raw).text;
    field.setAttribute("aria-label", prompt ? "Your own answer to: " + prompt : "Your own answer");
    field.hidden = true;
    form.fields.set(row, field);
    var anchor = owner;
    if (owner === row) {
      var label = row.closest("label") || (row.labels && row.labels[row.labels.length - 1]);
      if (label && (label.contains(row) || row.compareDocumentPosition(label) & Node.DOCUMENT_POSITION_FOLLOWING)) anchor = label;
    } else {
      while (anchor.nextElementSibling && anchor.nextElementSibling.hasAttribute("data-inf-recommendation")) anchor = anchor.nextElementSibling;
    }
    anchor.after(field);
    return field;
  }
  // Each Something else row's field shows only while the row is picked, and
  // keeps its words while it hides: they are sent only with the row.
  function offerWriteIns() {
    document.querySelectorAll('input[data-inf-write-in]:is([type="radio"], [type="checkbox"]), select option[data-inf-write-in]').forEach(function (row) {
      var field = writeInField(row);
      if (!field) return;
      var shown = rowPicked(row);
      if (field.hidden === shown) field.hidden = !shown;
    });
  }
  // Picking Something else puts the captain in its field, ready to write. A
  // pick the bridge restored (a revision's draft) moves no focus.
  function focusWriteIn(event) {
    var target = event.target;
    if (form.filling || form.locked || !target || !target.hasAttribute) return;
    var row = target.tagName === "SELECT"
      ? Array.prototype.find.call(target.selectedOptions, isWriteIn)
      : isWriteIn(target) && target.checked ? target : null;
    var field = row && form.fields.get(row);
    if (field && !field.hidden) field.focus();
  }
  function lockForm() {
    document.querySelectorAll("input, select, textarea, button, fieldset").forEach(function (control) {
      if (!control.disabled) control.disabled = true;
    });
  }
  function dressForm() {
    tagRecommendations();
    offerWriteIns();
  }
  function startForm() {
    dressForm();
    if (form.fill) fillForm(form.fill);
    form.fill = null;
    // A draft filled into a new document shows its rows' fields: no watch
    // heard that fill.
    offerWriteIns();
    if (form.locked) lockForm();
    if (!form.on) {
      form.on = true;
      var watch = function () { dressForm(); if (form.locked) lockForm(); readForm(); };
      document.addEventListener("input", watch, true);
      document.addEventListener("change", watch, true);
      document.addEventListener("change", focusWriteIn);
      new MutationObserver(watch).observe(document.documentElement, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["name", "value", "disabled", "required", "checked", "selected", "data-inf-recommended", "data-inf-write-in"]
      });
    }
    readForm();
  }
  var lastReported = "";
  var resizeQueued = false;
  var liveChange = false;
  function reading(height, width) {
    return height + ":" + width + ":" + initialized + ":" + (hold !== null);
  }
  function resize() {
    if (resizeQueued) return;
    resizeQueued = true;
    requestAnimationFrame(function () {
      resizeQueued = false;
      capFigures();
      if (!document.body) return;
      var height = document.body.getBoundingClientRect().height;
      var width = document.documentElement.clientWidth;
      var read = reading(height, width);
      if (read === lastReported) return;
      lastReported = read;
      var message = { type: "resize", height: height, width: width, initialized: initialized, live: liveChange };
      // A held page's drawing: prepared, its own behavior not started.
      if (hold) message.held = true;
      post(message);
      liveChange = false;
    });
  }
  // A released page reports its drawing at once, without waiting for a
  // frame: a hidden frame's frames are throttled, and the stage shows the
  // card on this report. What its scripts changed is that drawing.
  function reportDrawing() {
    capFigures();
    if (!initialized || !document.body) {
      lastReported = "";
      resize();
      return;
    }
    sizeWatch.takeRecords();
    var height = document.body.getBoundingClientRect().height;
    var width = document.documentElement.clientWidth;
    lastReported = reading(height, width);
    liveChange = false;
    post({ type: "resize", height: height, width: width, initialized: true, live: false });
  }
  var sizeWatch = new MutationObserver(function () {
    if (initialized && !settling) liveChange = true;
    resize();
  });
  sizeWatch.observe(document.documentElement, { childList: true, subtree: true, attributes: true, characterData: true });
  function keyLink(target) {
    return target && target.closest ? target.closest("a[data-inf-task]") : null;
  }
  function entryLink(target) {
    return target && target.closest ? target.closest("a[data-inf-entry]") : null;
  }
  function linkText(node) {
    var text = node.nodeValue;
    var parts = null;
    var at = 0;
    var match;
    KEY_IN_TEXT.lastIndex = 0;
    while ((match = KEY_IN_TEXT.exec(text))) {
      var task = keys.known && keys.known[match[0]];
      var entry = !task && entries.known && Object.prototype.hasOwnProperty.call(entries.known, match[0]) ? entries.known[match[0]] : null;
      if (!task && !entry) continue;
      parts = parts || document.createDocumentFragment();
      if (match.index > at) parts.appendChild(document.createTextNode(text.slice(at, match.index)));
      var link = document.createElement("a");
      if (task) {
        link.setAttribute("data-inf-task", match[0]);
      } else {
        link.setAttribute("data-inf-entry", match[0]);
        link.setAttribute("data-inf-standing", entry.tone);
        link.setAttribute("aria-label", entry.label);
        link.setAttribute("title", entry.label);
      }
      link.setAttribute("role", "link");
      link.setAttribute("tabindex", "0");
      link.textContent = match[0];
      parts.appendChild(link);
      at = match.index + match[0].length;
    }
    if (!parts) return false;
    if (at < text.length) parts.appendChild(document.createTextNode(text.slice(at)));
    node.parentNode.replaceChild(parts, node);
    return true;
  }
  // A reference already linked takes its entry's words and mark as they stand now.
  function refreshEntries() {
    if (!entries.known || !document.body) return;
    var changed = false;
    document.querySelectorAll("a[data-inf-entry]").forEach(function (link) {
      var id = link.getAttribute("data-inf-entry");
      var entry = Object.prototype.hasOwnProperty.call(entries.known, id) ? entries.known[id] : null;
      if (!entry) return;
      if (link.getAttribute("data-inf-standing") !== entry.tone) {
        link.setAttribute("data-inf-standing", entry.tone);
        changed = true;
      }
      if (link.getAttribute("aria-label") !== entry.label) {
        link.setAttribute("aria-label", entry.label);
        link.setAttribute("title", entry.label);
        changed = true;
      }
    });
    // The same words in the same place: a mark is not the body changing.
    if (changed) sizeWatch.takeRecords();
  }
  // The key lit by a rest elsewhere in the window (INF-237) takes the hover mark, on every link to it.
  function markLit() {
    document.querySelectorAll("a[data-inf-task]").forEach(function (link) {
      var on = keys.lit !== null && link.getAttribute("data-inf-task") === keys.lit;
      if (on === link.hasAttribute("data-inf-lit")) return;
      if (on) link.setAttribute("data-inf-lit", "");
      else link.removeAttribute("data-inf-lit");
    });
    // A mark is not the body changing.
    sizeWatch.takeRecords();
  }
  function linkKeys() {
    if ((!keys.known && !entries.known) || !document.body) return;
    var found = [];
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    for (var node = walker.nextNode(); node; node = walker.nextNode()) {
      if (node.nodeValue.indexOf("-") < 0 || !node.parentElement) continue;
      if (node.parentElement.closest(UNLINKED)) continue;
      found.push(node);
    }
    var linked = false;
    found.forEach(function (text) { if (linkText(text)) linked = true; });
    if (!linked) return;
    markLit();
    // The same words in the same place: linking is not the body changing.
    sizeWatch.takeRecords();
    keyWatch.takeRecords();
    resize();
  }
  var keyWatch = new MutationObserver(function () {
    if (keys.known || entries.known) linkKeys();
    tagPictures();
    if (decorateDemos()) {
      // A demo the body's own script added: its button is part of that change.
      keyWatch.takeRecords();
    }
  });
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", decorateDemos, { once: true });
  else decorateDemos();
  keyWatch.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
  function keyOf(link) {
    return link.getAttribute("data-inf-task");
  }
  function openKey(link) {
    post({ type: "task", gesture: "open", key: keyOf(link) });
  }
  function openEntry(link) {
    post({ type: "entry", id: link.getAttribute("data-inf-entry") });
  }
  function leaveKey() {
    var link = keys.rested;
    if (!link) return;
    keys.rested = null;
    post({ type: "task", gesture: "leave", key: keyOf(link) });
  }
  function restKey(link) {
    keys.rested = link;
    var box = link.getBoundingClientRect();
    post({ type: "task", gesture: "rest", key: keyOf(link), box: { top: box.top, right: box.right, bottom: box.bottom, left: box.left } });
  }
  function quietKey() {
    if (!keys.rested) return false;
    keys.quiet = keys.rested;
    leaveKey();
    return true;
  }
  document.addEventListener("pointerover", function (event) {
    var link = keyLink(event.target);
    // Coming in from outside the frame: the host has let go of whatever
    // rested, and the pointer has left any key it was asked to keep quiet.
    if (!event.relatedTarget) keys.quiet = null;
    if (link !== keys.rested) leaveKey();
    if (!link || link === keys.quiet) return;
    restKey(link);
  });
  document.addEventListener("pointerout", function (event) {
    var link = keyLink(event.target);
    if (!link || (event.relatedTarget && link.contains(event.relatedTarget))) return;
    if (link === keys.quiet) keys.quiet = null;
    if (link === keys.rested) leaveKey();
  });
  document.addEventListener("pointerdown", function (event) {
    if (keyLink(event.target)) quietKey();
  }, true);
  var quieted = null;
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && quietKey()) quieted = event;
    var link = keyLink(event.target);
    if (event.key === "Enter" && link && link === event.target) {
      event.preventDefault();
      openKey(link);
    }
    var reference = entryLink(event.target);
    if (event.key === "Enter" && reference && reference === event.target) {
      event.preventDefault();
      openEntry(reference);
    }
  }, true);
  // The keyboard rests on a key as the pointer does, and leaving it lets go.
  document.addEventListener("focusin", function (event) {
    var target = event.target;
    if (target && target.nodeType === 1 && target !== document.body) {
      held.element = target;
      held.start = null;
    }
    var link = keyLink(target);
    if (link !== keys.rested) leaveKey();
    if (!link || link !== target || link === keys.quiet || !link.matches(":focus-visible")) return;
    // Once the window has brought the key into view, where its summary goes.
    requestAnimationFrame(function () { requestAnimationFrame(function () {
      if (document.activeElement === link && keys.rested !== link) restKey(link);
    }); });
  }, true);
  document.addEventListener("focusout", function (event) {
    var target = event.target;
    // Focus that moved in a page whose process was not yet told it holds the
    // window's focus fired no focusin (Chromium sends it on the page's focus,
    // which a move to another page can pass by): the element focus leaves is
    // the one the page held, unless a press in the body moved it.
    if (target !== held.element && !pressing && target && target.nodeType === 1 && target !== document.body) {
      held.element = target;
    }
    if (target === held.element && typeof target.selectionStart === "number") {
      held.start = target.selectionStart;
      held.end = target.selectionEnd;
      held.direction = target.selectionDirection;
    } else if (target === held.element) {
      held.start = null;
    }
    var link = keyLink(target);
    if (!link) return;
    if (link === keys.quiet) keys.quiet = null;
    if (link === keys.rested) leaveKey();
  }, true);
  // A press elsewhere in the body leaves the field it held for whatever the
  // press focuses, in the same task as the press.
  var pressing = false;
  document.addEventListener("pointerdown", function (event) {
    if (held.element && !held.element.contains(event.target)) held.element = null;
    pressing = true;
    setTimeout(function () { pressing = false; });
  }, true);
  // The host gave the frame focus back (an overlay over the window closed):
  // the field it held takes it again, its caret where it was - unless focus
  // has moved on from the frame since (a command chosen in search moved it).
  function returnFocus() {
    var element = held.element;
    if (!document.hasFocus()) return;
    if (!element || !element.isConnected || element.disabled || boxless(element)) return;
    element.focus({ preventScroll: true });
    if (held.start !== null && typeof element.setSelectionRange === "function") {
      try { element.setSelectionRange(held.start, held.end, held.direction || "none"); } catch (error) {}
    }
  }
  // After the body's own handlers: a picture opens on Enter or Space, and
  // an Escape nothing in the body used leaves the body for its card.
  document.addEventListener("keydown", function (event) {
    if (event.defaultPrevented || event.isComposing) return;
    var target = event.target;
    if ((event.key === "Enter" || event.key === " ") && target && target.nodeType === 1 && target.hasAttribute("data-inf-picture")) {
      event.preventDefault();
      if (!event.repeat) openPicture(target);
      return;
    }
    if (event.key !== "Escape" || !caps.escape || event.repeat || quieted === event) return;
    if (document.querySelector("dialog:modal, :popover-open")) return;
    if (target && target.tagName === "INPUT" && target.type === "search" && target.value !== "") return;
    post({ type: "escape" });
  });
  document.addEventListener("scroll", leaveKey, true);
  new ResizeObserver(resize).observe(document.documentElement);
  window.addEventListener("load", resize);
  ["click", "focusin", "input", "keydown"].forEach(function (type) {
    document.addEventListener(type, function () { post({ type: "interaction" }); }, true);
  });
  // The window's focus moving between two frames passes the page by: each
  // frame says when its own window gains or loses it. Heard before any
  // script of the body's and sent through what the bridge held from its
  // start, so the body cannot keep its frame from saying it.
  var host = window.parent;
  var apply = Reflect.apply;
  var targetOf = Object.getOwnPropertyDescriptor(Event.prototype, "target").get;
  ["focus", "blur"].forEach(function (type) {
    window.addEventListener(type, function (event) {
      if (apply(targetOf, event, []) !== window) return;
      host.postMessage({ fm: VERSION, type: "focused", document: documentId, focused: type === "focus" }, "*");
    }, true);
  });
  // A press beginning in the frame passes the page by too: the frame says
  // so, the same way, before the press's own click or key is sent.
  var repeatOf = Object.getOwnPropertyDescriptor(KeyboardEvent.prototype, "repeat").get;
  window.addEventListener("pointerdown", function () {
    host.postMessage({ fm: VERSION, type: "pressed", document: documentId }, "*");
  }, true);
  window.addEventListener("keydown", function (event) {
    if (apply(repeatOf, event, [])) return;
    host.postMessage({ fm: VERSION, type: "pressed", document: documentId }, "*");
  }, true);
  post({ type: "ready", reuseReads: true });
})();`,HA="sha256-kyKGhteYf8iScLYERPNPWiHDGk1PY0lZ90Dcw46ddKg=",_e=d().int().positive().max(Number.MAX_SAFE_INTEGER),G=p(Ji),qA=["get","set","delete","list"],Li=128,jA=R("verb",[f({verb:p("subscribe"),sub:_e,read:a().min(1).max(64),args:V(a(),j()).default({})}),f({verb:p("unsubscribe"),sub:_e}),f({verb:p("action"),action:a().min(1).max(200),value:j().optional()}),f({verb:p("fetch"),alias:a().min(1).max(32),request:Mi}),f({verb:p("store"),op:g(qA),key:a().min(1).max(Li).optional(),value:j().optional(),prefix:a().max(Li).optional()})]),Pi=f({src:a().min(1).max(GA),alt:a().max(MA),width:d().int().nonnegative(),height:d().int().nonnegative()}),nt=d().int().nonnegative().max(et),VA=Bi.extend({written:a().min(1).max(Ei).optional()}),XA=f({answered:nt,of:nt,changed:nt,picked:nt,answers:w(VA).max(et)}),$A=["rest","leave","open"],eu=f({top:d().finite(),right:d().finite(),bottom:d().finite(),left:d().finite()}),tu=R("type",[f({fm:G,type:p("revealed"),document:a(),seq:_e,offerId:a().min(1).max(64),top:d().finite().nonnegative().max(1e6).optional(),height:d().finite().nonnegative().max(1e6).optional()}),f({fm:G,type:p("ready"),document:a().optional(),reuseReads:S().optional()}),f({fm:G,type:p("request"),id:_e}).loose(),f({fm:G,type:p("resize"),height:d().finite().nonnegative(),document:a().optional(),width:d().finite().nonnegative().optional(),initialized:S().optional(),live:S().optional(),held:S().optional()}),f({fm:G,type:p("link"),href:a().min(1).max(2048)}),f({fm:G,type:p("draft"),document:a(),text:a().min(1).max(LA).regex(/^[^\r\n]*$/)}),f({fm:G,type:p("image"),index:d().int().nonnegative(),pictures:w(Pi).min(1).max(TA)}),f({fm:G,type:p("demo"),src:a().min(1).max(YA),poster:Pi,caption:a().max(Yi),durationMs:d().int().nonnegative(),play:S()}),f({fm:G,type:p("interaction"),document:a()}),f({fm:G,type:p("focused"),document:a(),focused:S()}),f({fm:G,type:p("pressed"),document:a()}),f({fm:G,type:p("escape"),document:a()}),f({fm:G,type:p("task"),document:a(),gesture:g($A),key:a().regex(NA),box:eu.optional()}),f({fm:G,type:p("entry"),document:a(),id:a().regex(BA)}),f({fm:G,type:p("pong"),seq:_e}),XA.extend({fm:G,type:p("answers"),seq:_e.optional(),questions:j().optional(),questionsGap:Di.optional()})]),ae="app-frame",Hi="images",qi="media",nu={mp4:"video/mp4",gif:"image/gif"},iu={png:"image/png",jpg:"image/jpeg",webp:"image/webp"},ru=/^([A-Za-z0-9_-]{1,64})-([0-9a-f]{32})\.(png|jpg|webp)$/,ou=/^([A-Za-z0-9_-]{1,64})-([0-9a-f]{32})\.(mp4|gif)$/;function ji(e){const t=ru.exec(e);if(!t)return;const[,n,,i]=t;if(!(!n||!i))return{taskId:n,fileName:e,contentType:iu[i]}}function Vi(e){const t=ou.exec(e);if(!t)return;const[,n,,i]=t;if(!n||!i)return;const r=i;return{taskId:n,fileName:e,kind:r,contentType:nu[r]}}function au(e){const t=`${ae}://${qi}/`;return e.startsWith(t)?Vi(e.slice(t.length))?.kind:void 0}const su=new RegExp(`data-(?:${Ee.join("|")})-demo="([^"]*)"`,"g");function cu(e){return au(e)!==void 0}function lu(e){const t=new Set;for(const n of e.matchAll(su)){const i=n[1]??"";cu(i)&&t.add(i)}return t}const Au=/^data:image\/(png|jpeg|gif|webp)[;,]/;function Xi(e){if(Au.test(e))return!0;const t=`${ae}://${Hi}/`;return e.startsWith(t)&&ji(e.slice(t.length))!==void 0}function $i(e,t){const n=t[e];if(!n||!Xi(n.src))return;const i=t.filter(r=>Xi(r.src));return{index:i.indexOf(n),pictures:i}}const uu=["allow-scripts"].join(" "),du=`${ae}:`,hu=`${ae}://fonts`,fu=`data: ${ae}:`;function Kt(e=[],t=du){const n=[HA,...e].map(i=>`'${i}'`).join(" ");return`default-src 'none'; style-src 'unsafe-inline'; font-src ${t}; img-src ${fu}; script-src ${n}`}Kt(),Kt([],hu);const er=["v_version_v1","v_tasks_v1","v_task_events_v1","v_usage_v1","v_feed_v1","v_quota_windows_v1","v_routing_v1","v_placements_v1","v_projects_v1","v_repos_v1"],pu=/^v_[a-z][a-z0-9_]*_v[1-9][0-9]*$/,We=a().regex(pu,{message:"a versioned view name, such as v_usage_v1"}),it={textBytes:4096,params:32,paramBytes:4096};function tr(e){return new TextEncoder().encode(e).byteLength}const nr=q([a().refine(e=>tr(e)<=it.paramBytes,"a param is at most 4 KB"),d().finite(),Xe()]),ir=a().min(1).refine(e=>tr(e)<=it.textBytes,"a query is at most 4 KB");b({sql:ir,params:w(nr).max(it.params).optional()}),b({sql:ir,params:w(nr).max(it.params).optional(),views:w(We).max(64)});const mu=["sql_view_not_declared","sql_not_readonly","sql_invalid","sql_timeout","sql_too_large"],gu=q([a(),d(),Xe()]),wu=f({columns:w(a()),rows:w(V(a(),gu)),truncated:S(),elapsedMs:d()}),bu=f({refused:g(mu),message:a()});q([bu,wu]);const rt={"commands.search":{label:"Search commands",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"k",meta:!0}]},"focus.main-message":{label:"Go to the main message",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"l",meta:!0}]},"focus.card-reply":{label:"Go to the card's reply",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"l",meta:!0,shift:!0}],searchWords:["anything to add","comment"]},"focus.card-body":{label:"Go to the card's body",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"focus.card-actions":{label:"Go to the card's buttons",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"cards.choice-1":{label:"Press the recommended choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"1",meta:!0}],searchWords:["card","button","default","first"]},"cards.choice-2":{label:"Press the second choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"2",meta:!0}],searchWords:["card","button"]},"cards.choice-3":{label:"Press the third choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"3",meta:!0}],searchWords:["card","button"]},"cards.choice-4":{label:"Press the fourth choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"4",meta:!0}],searchWords:["card","button"]},"regions.next":{label:"Go to the next part of the window",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"F6"}]},"regions.previous":{label:"Go to the previous part of the window",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"F6",shift:!0}]},"computers.previous":{label:"Previous work computers",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"computers.next":{label:"Next work computers",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"project-focus.open":{label:"Focus on a project",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[{key:"p",meta:!0,shift:!0}],searchWords:["filter","project","pill"]},"project-focus.clear":{label:"Show all projects",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["filter","focus","project","clear"]},"cards.previous":{label:"Show the previous card",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"[",meta:!0,shift:!0},{key:"{",meta:!0,shift:!0}]},"cards.next":{label:"Show the next card",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"]",meta:!0,shift:!0},{key:"}",meta:!0,shift:!0}]},"cards.close":{label:"Close the shown card",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[]},"cards.minimize":{label:"Put card aside",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[{key:"m",meta:!0,shift:!0}]},"cards.maximize":{label:"Maximize or restore card",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["full","screen","enlarge","expand","bigger"]},"cards.next-revision":{label:"Go to the next revised area",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["changes","revision","links"]},"cards.thread":{label:"Show or hide the card's thread",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"\\",meta:!0}],searchWords:["collapse","expand","chat","replies","messages"]},"cards.show-info":{label:"Show Info",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","record","tab","open"]},"cards.show-cards":{label:"Show Cards",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","record","tab","decisions","notes"]},"cards.show-activity":{label:"Show Activity",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","record","tab","timeline","history"]},"cards.show-crewmate":{label:"Show Crewmate",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","session","transcript","tab"]},"browser.control":{label:"Take or return browser control",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["handback","take","return","browser"]},"task.move-computer":{label:"Move the task to another computer",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["computer","mac","machine","move","device","record"]},"cards.show-browser":{label:"Show Browser",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","page","tab"]},"cards.next-tab":{label:"Next tab",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","tab"]},"cards.previous-tab":{label:"Previous tab",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","tab"]},"settings.open":{label:"Open Settings",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:",",meta:!0}]},"settings.keyboard":{label:"Open Keyboard settings",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"settings.panels":{label:"Arrange panels",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["rails","layout","order","move","hide","show"]},"updates.show":{label:"Show available update",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["update","restart","stable","alpha"]},"updates.later":{label:"Update later",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["update","later","cancel","saving","work"]},"updates.check":{label:"Check for updates",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["update","version","release","new"]},"whats-new.show":{label:"Show what's new",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["release","notes","changes","version"]},"firstmate.reply":{label:"Open the first mate's reply",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["answer","message","note","last"]},"settings.runbooks":{label:"Open Runbooks",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["guidance","skills","instructions"]},"runbooks.open-folder":{label:"Open your runbooks folder",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["directory","guidance","customize"]},"settings.usage":{label:"Open Usage",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["tokens","models","cost","dollars"]},"settings.automation":{label:"Open Automation",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["schedule","scheduled","recurring","reminder","pause"]},"settings.integrations":{label:"Open Integrations",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["github","connection","connect","sign in"]},"automation.pause-all":{label:"Pause all automations",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["schedule","scheduled","recurring","stop"]},"usage.unit":{label:"Switch Usage units",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["tokens","cost","dollars","estimate"]},"allowance.recheck":{label:"Recheck allowance",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["quota","refresh","usage","limit","account","switch"]},"devices.try-again":{label:`Try again to reach your ${{many:"computers"}.many}`,scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["devices","ssh","reconnect","connect","macs"],section:"devices"},"size.larger":{label:"Make everything larger",scope:"window",runs:"main",repeat:!0,risk:"view",keys:[{key:"+",meta:!0},{key:"=",meta:!0},{key:"+",ctrl:!0},{key:"=",ctrl:!0}]},"size.smaller":{label:"Make everything smaller",scope:"window",runs:"main",repeat:!0,risk:"view",keys:[{key:"-",meta:!0},{key:"-",ctrl:!0}]},"size.reset":{label:"Return to the usual size",scope:"window",runs:"main",repeat:!0,risk:"view",keys:[{key:"0",meta:!0},{key:"0",ctrl:!0}]},"message.delete-to-line-start":{label:"Delete back to the start of the line",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"u",ctrl:!0}]},"message.delete-to-line-end":{label:"Delete to the end of the line",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"k",ctrl:!0}]},"message.delete-word-before":{label:"Delete the word before the cursor",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"w",ctrl:!0}]},"message.put-back-deleted":{label:"Put back what was last deleted",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"y",ctrl:!0}]},"message.recall":{label:"Bring back the last message sent",scope:"main-message",repeat:!1,risk:"edit",keys:[{key:"ArrowUp"},{key:"p",ctrl:!0}]}};function yu(e){return rt[e].scope==="window"}function rr(e){return rt[e].runs==="shell"}const Tt=Object.keys(rt);Tt.filter(rr),Tt.filter(e=>yu(e)&&!rr(e));function or(e,t){return t==="mac"||!e.meta&&!e.ctrl?e:e.ctrl?null:{key:e.key,ctrl:!0,...e.alt?{alt:!0}:{},...e.shift?{shift:!0}:{}}}function vu(e,t){if(t==="mac")return e;const n=[];for(const i of e){const r=or(i,t),s=i.second?or(i.second,t):void 0;if(!r||s===null)continue;const o=s?{...r,second:s}:r;n.some(c=>JSON.stringify(c)===JSON.stringify(o))||n.push(o)}return n}function ku(e,t="mac"){return vu(rt[e].keys,t)}function Iu(e){return Object.fromEntries(Tt.map(t=>[t,ku(t,e)]))}Iu("mac");const ar=g(["regular","wide","full"]),sr=g(["content","fill"]),xu=g(["open","search","add","list","note","filter","clock","chart"]),Su=3,Cu=16,ot=16,cr=3072,lr=4096,De=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/,ue=a().min(1).max(32).regex(De,"kebab-case"),Eu=/^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$/,Ar=a().regex(Eu,"a plain id"),ur=a().min(1).max(80),at=di(()=>q([Xe(),S(),d().finite(),a(),w(at),V(a(),at)])),st=at.refine(e=>JSON.stringify(e).length<=cr,`a card's data is at most ${cr} bytes of JSON`);at.refine(e=>new TextEncoder().encode(JSON.stringify(e)).byteLength<=lr,`a card keeps at most ${lr} bytes of JSON`);const Bu=b({view:ue,title:ur,width:ar.optional(),height:sr.optional(),data:st.optional()}),_u=b({id:ue,icon:xu,label:a().min(1).max(40),emits:ue.optional(),data:st.optional()}),Du=b({id:ue,label:a().min(1).max(60),emits:ue.optional(),presses:ue.optional(),data:st.optional(),key:a().min(1).max(12).refine(e=>Fu(e)!==null,"a key as a Mac writes it, such as ⌘B").optional(),words:w(a().min(1).max(24).regex(/^\S+$/,"one word")).max(8).optional()}).refine(e=>e.emits===void 0!=(e.presses===void 0),"a command either emits a card or presses a header button");b({id:Ar.optional(),view:ue,title:ur,width:ar.optional(),height:sr.optional(),data:st.optional()});const Gt=V(ue,Bu).refine(e=>Object.keys(e).length<=ot,`at most ${ot} named cards`),Mt=w(_u).max(Su),Jt=w(Du).max(Cu),Nu={"⌃":"ctrl","⌥":"alt","⇧":"shift","⌘":"meta"};function Fu(e){const t={key:""};let n=e;for(;n.length>0;){const i=Nu[n[0]];if(!i)break;if(t[i])return null;t[i]=!0,n=n.slice(1)}return/^F([1-9]|1[0-9]|2[0-4])$/.test(n)?{...t,key:n}:[...n].length!==1||/\s/.test(n)?null:{...t,key:/^[A-Za-z]$/.test(n)?n.toLowerCase():n}}const dr=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/,Zu=a().min(2).max(64).regex(dr,"kebab-case id"),Yt=a().min(1).max(64).regex(dr,"kebab-case id"),Ru=/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/,Qu=g(["decision","note","attention","record"]),Ou=b({kind:Yt,chrome:Qu,body:b({streaming:g(["plain","html"])})}),Uu=b({id:Yt,label:a().min(1).max(24),order:d().int().min(0).max(1e3),width:g(["standard","wide"]).default("wide")}),Wu=g(["left","right"]),zu=g(["top","bottom"]),Ku=b({x:Wu,y:zu}),Tu=g(["content","fill"]),Gu=b({id:Yt,title:a().min(1).max(40),preferredPlacement:Ku,order:d().int().min(0).max(1e3),size:Tu.default("content"),newestLast:S().default(!1),cardViews:w(a().regex(De)).max(ot).optional(),cards:Gt.optional(),header:Mt.optional(),commands:Jt.optional()});function Lt(e,t,n,i){const r=new Set;for(const s of e){const o=t(s);r.has(o)&&n.addIssue({code:"custom",message:`duplicate ${i} id "${o}"`}),r.add(o)}}const Mu=b({cardKinds:w(Ou).default([]).superRefine((e,t)=>Lt(e,n=>n.kind,t,"card-kind")),settingsSections:w(Uu).default([]).superRefine((e,t)=>Lt(e,n=>n.id,t,"settings-section")),sidePanels:w(Gu).default([]).superRefine((e,t)=>Lt(e,n=>n.id,t,"side-panel"))}),hr=1048576;function ct(e){return`"${e}" is retired: a panel reaches a service outside your projects only through an integration. Name the connection, its actions and why under "integrations".`}const fr=a().min(1).max(64).regex(/^[^\s/][^/]*$/,"a name with no slash"),Ju=a().min(1).max(48).regex(/^[^\s/][^/]*$/,"a name with no slash"),Yu=b({integration:fr,actions:w(fr).optional(),events:w(Ju).optional(),why:a().trim().min(1)}).superRefine((e,t)=>{!e.actions?.length&&!e.events?.length&&t.addIssue({code:"custom",message:`"${e.integration}" names no action and no event`})}),pr=w(Yu).superRefine((e,t)=>{const n=new Set;for(const i of e){const r=i.integration.trim().toLowerCase();n.has(r)&&t.addIssue({code:"custom",message:`"${i.integration}" is named twice`}),n.add(r)}}),Lu=a().min(1).max(64).regex(/^[a-z][a-z0-9-]*(?:\.[a-z][a-z0-9-]*)*$/,"dotted read-catalog name"),Pu=b({net:Ce({message:ct("net")}).optional(),secrets:Ce({message:ct("secrets")}).optional(),integrations:pr.optional(),storage:b({kv:b({maxBytes:d().int().positive().max(hr)})}).optional(),reads:w(Lu).max(64).optional(),sql:w(We).max(er.length).optional(),moves:p(!0).optional()});b({id:Zu,name:a().min(1).max(40),version:a().regex(Ru,"semver"),contributes:Mu,capabilities:Pu});const Hu=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/,de=a().min(2).max(48).regex(Hu),qu=["yours","installed"],Pt=128,ze=["computers.resources","quota.snapshot","tasks.board","tasks.detail","tasks.search","feed.recent","forge.changes","automation.list","knowledge.collections","knowledge.graph","knowledge.concepts","knowledge.directions","knowledge.findings","knowledge.entry","knowledge.direction"],mr=g(ze),Ke=di(()=>q([Xe(),S(),d().finite(),a(),w(Ke),V(a(),Ke)])),ju=f({key:a(),value:Ke,updatedAt:d()}),Vu=q([b({always:p(!0)}),b({store:a().min(1).max(Pt),when:p("nonEmpty")}),b({code:p(!0)})]),gr=b({x:g(["left","right"]),y:g(["top","bottom"])});b({api:q([p(1),p(2)],{message:"this panel is written for a version of the panel API this app does not serve"}).optional(),name:a().min(1).max(40).optional(),version:a().regex(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/,"semver").optional(),title:a().min(1).max(40).optional(),placement:gr.optional(),order:d().int().min(0).max(1e3).optional(),size:g(["content","fill"]).optional(),newestLast:S().optional(),presence:Vu.optional(),cards:Gt.optional(),header:Mt.optional(),commands:Jt.optional(),reads:w(mr).max(ze.length).optional(),moves:p(!0).optional(),sql:w(We).max(64).optional(),integrations:pr.optional(),net:Ce({message:ct("net")}).optional(),secrets:Ce({message:ct("secrets")}).optional(),storage:b({kv:b({maxBytes:d().int().positive().max(hr)})}).optional(),origin:b({taskId:a().min(1).max(64).optional()}).optional()}),new Set(ze),new Set(er);const Xu=f({stage:g(["manifest","panel","server"]),message:a()}),wr=f({id:de,source:g(qu),by:a().min(1).max(40).nullable(),title:a().min(1).max(40),placement:gr,order:d().int(),size:g(["content","fill"]),newestLast:S().optional(),present:S(),ownPresence:S(),moves:S(),running:S(),reads:w(mr),sql:w(We),panel:f({url:a(),version:a()}).nullable(),frame:f({version:a()}).nullable(),cardViews:w(a().regex(De)).max(ot),cards:Gt,header:Mt,commands:Jt,server:f({actions:w(a()),background:w(f({id:a(),everyMs:d()}))}).nullable(),error:Xu.nullable(),stopped:f({reason:g(["unresponsive","exited"]),at:a(),version:a()}).optional(),paused:f({api:d().int().min(1),serves:w(d().int().min(1)),asked:S()}).optional(),integrationAsks:w(f({integration:a().min(1).max(200),place:a().min(1).max(200),action:a().min(1).max(200),label:a().min(1).max(200),state:g(["asking","declined"])})).optional()});f({extensions:w(wr),drafts:w(wr).optional()}),f({extensionId:de,key:a(),draft:p(!0).optional()});const Ht=a().min(1).max(Pt),Te=p(!0).optional();R("op",[f({op:p("get"),extensionId:de,key:Ht,draft:Te}),f({op:p("set"),extensionId:de,key:Ht,value:Ke,draft:Te}),f({op:p("delete"),extensionId:de,key:Ht,draft:Te}),f({op:p("list"),extensionId:de,prefix:a().max(Pt).optional(),draft:Te})]),f({value:Ke.optional(),entries:w(ju).optional()}),f({draft:Te}),R("op",[f({op:p("list")}),f({op:p("show"),name:a().min(1).max(200)}),f({op:p("call"),name:a().min(1).max(200),action:a().min(1).max(200),input:j().optional()})]),q([f({text:a(),refused:g(["refused","invalid"]).optional()}),w(V(a(),j())),V(a(),j())]),q([f({ok:p(!0),result:j()}),f({ok:p(!1),error:a()})]);const $u=["activity","automation","knowledge","now"],lt=524288;function qt(e){const t=new RegExp(`</${e}`,"i");return n=>!t.test(n)}const ed=b({html:a().max(lt).refine(qt("body"),"a </body> tag"),script:a().min(1).max(lt).refine(qt("script"),"a <\/script> tag").optional()}),td=b({html:a().max(lt)}),nd=g(["dark","light"]),jt=b({title:a().min(1).max(120),theme:nd,style:a().max(lt).refine(qt("style"),"a </style> tag")}),id=jt.extend({template:ed,kind:dl().optional()}),rd=jt.extend({template:td,kind:p("card")}),od=R("source",[b({source:p("builtin"),id:g($u),view:a().regex(De).optional()}),b({source:p("installed"),id:de,version:a().regex(/^[0-9a-f]{16}$/),view:a().regex(De).optional()}),b({source:p("personal"),id:de,version:a().regex(/^[0-9a-f]{16}$/),draft:p(!0).optional(),view:a().regex(De).optional()})]),ad=b({id:a().min(1).max(64).regex(/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/),reads:w(g(ze)).max(ze.length),sql:w(We).max(64),card:b({id:Ar}).optional(),moves:S().optional(),server:S().optional()}),sd=jt.extend({kind:p("panel"),panel:od,config:ad});q([rd,sd,id]),f({mountId:a().min(1).max(64),url:a().startsWith(`${ae}://`)});function cd(e){return`${ae}://fonts/${e}`}function Vt(e){return e.replaceAll("&","&amp;").replaceAll('"',"&quot;").replaceAll("<","&lt;")}function ld(e){const t=Vt(e.theme);return["<!doctype html>",`<html data-theme="${t}"${e.held?" data-inf-held":""}>`,"<head>",`<meta http-equiv="Content-Security-Policy" content="${Vt(e.csp)}">`,'<meta charset="utf-8">',...e.title?[`<title>${Vt(e.title)}</title>`]:[],`<style>${e.style}</style>`,`<script>${PA}<\/script>`,"</head>",`<body data-theme="${t}">`,e.html,...e.script?[`<script>${e.script}<\/script>`]:[],"</body>","</html>"].join(`
`)}const Ad=/https?:\/\/[^\s<>"'`]+/gi;function Xt(e,t,n){let i=0;for(const r of e)r===t?i+=1:r===n&&(i-=1);return i<0}function ud(e){let t=e,n="";for(;t.length>0;){const i=t[t.length-1];if(!i||!(/[.,;:!?']/.test(i)||i===")"&&Xt(t,"(",")")||i==="]"&&Xt(t,"[","]")||i==="}"&&Xt(t,"{","}")))break;t=t.slice(0,-1),n=i+n}return{url:t,trailing:n}}function dd(e){try{const t=new URL(e);return t.protocol==="http:"||t.protocol==="https:"}catch{return!1}}function br(e){try{const t=new URL(e);if(t.protocol==="https:")return!0;if(t.protocol==="http:"){const n=t.hostname.toLowerCase();return n==="localhost"||n.endsWith(".localhost")||n==="127.0.0.1"||n==="::1"||n==="[::1]"}return!1}catch{return!1}}function hd(e){const t=[];let n=0;for(const i of e.matchAll(Ad)){const r=i.index??0,{url:s}=ud(i[0]);!s||!dd(s)||(r>n&&t.push({type:"text",value:e.slice(n,r)}),t.push({type:"url",value:s}),n=r+s.length)}return n<e.length&&t.push({type:"text",value:e.slice(n)}),t}const fd=new Map([[0,65533],[128,8364],[130,8218],[131,402],[132,8222],[133,8230],[134,8224],[135,8225],[136,710],[137,8240],[138,352],[139,8249],[140,338],[142,381],[145,8216],[146,8217],[147,8220],[148,8221],[149,8226],[150,8211],[151,8212],[152,732],[153,8482],[154,353],[155,8250],[156,339],[158,382],[159,376]]);function pd(e){return e>=55296&&e<=57343||e>1114111?65533:fd.get(e)??e}function yr(e){const t=atob(e),n=t.length&-2,i=new Uint16Array(n/2);for(let r=0,s=0;r<n;r+=2){const o=t.charCodeAt(r),c=t.charCodeAt(r+1);i[s++]=o|c<<8}return i}const md=yr("QR08ALkAAgH6AYsDNQR2BO0EPgXZBQEGLAbdBxMISQrvCmQLfQurDKQNLw4fD4YPpA+6D/IPAAAAAAAAAAAAAAAAKhBMEY8TmxUWF2EYLBkxGuAa3RsJHDscWR8YIC8jSCSIJcMl6ie3Ku8rEC0CLjoupS7kLgAIRU1hYmNmZ2xtbm9wcnN0dVQAWgBeAGUAaQBzAHcAfgCBAIQAhwCSAJoAoACsALMAbABpAGcAO4DGAMZAUAA7gCYAJkBjAHUAdABlADuAwQDBQHIiZXZlAAJhAAFpeW0AcgByAGMAO4DCAMJAEGRyAADgNdgE3XIAYQB2AGUAO4DAAMBA8CFoYZFj4SFjcgBhZAAAoFMqAAFncIsAjgBvAG4ABGFmAADgNdg43fAlbHlGdW5jdGlvbgCgYSBpAG4AZwA7gMUAxUAAAWNzpACoAHIAAOA12Jzc6SFnbgCgVCJpAGwAZABlADuAwwDDQG0AbAA7gMQAxEAABGFjZWZvcnN1xQDYANoA7QDxAPYA+QD8AAABY3LJAM8AayNzbGFzaAAAoBYidgHTANUAAKDnKmUAZAAAoAYjeQARZIABY3J0AOAA5QDrAGEidXNlAACgNSLuI291bGxpcwCgLCFhAJJjcgAA4DXYBd1wAGYAAOA12Dnd5SF2ZdhiYwDyAOoAbSJwZXEAAKBOIgAHSE9hY2RlZmhpbG9yc3UXARoBHwE6AVIBVQFiAWQBZgGCAakB6QHtAfIBYwB5ACdkUABZADuAqQCpQIABY3B5ACUBKAE1AfUhdGUGYWmg0iJ0KGFsRGlmZmVyZW50aWFsRAAAoEUhbCJleXMAAKAtIQACYWVpb0EBRAFKAU0B8iFvbgxhZABpAGwAO4DHAMdAcgBjAAhhbiJpbnQAAKAwIm8AdAAKYQABZG5ZAV0BaSJsbGEAuGB0I2VyRG90ALdg8gA5AWkAp2NyImNsZQAAAkRNUFRwAXQBeQF9AW8AdAAAoJkiaSJudXMAAKCWIuwhdXMAoJUiaSJtZXMAAKCXIm8AAAFjc4cBlAFrKndpc2VDb250b3VySW50ZWdyYWwAAKAyImUjQ3VybHkAAAFEUZwBpAFvJXVibGVRdW90ZQAAoB0gdSJvdGUAAKAZIAACbG5wdbABtgHNAdgBbwBuAGWgNyIAoHQqgAFnaXQAvAHBAcUB8iJ1ZW50AKBhIm4AdAAAoC8i7yV1ckludGVncmFsAKAuIgABZnLRAdMBAKACIe8iZHVjdACgECJuLnRlckNsb2Nrd2lzZUNvbnRvdXJJbnRlZ3JhbAAAoDMi7yFzcwCgLypjAHIAAOA12J7ccABDoNMiYQBwAACgTSKABURKU1phY2VmaW9zAAsCEgIVAhgCGwIsAjQCOQI9AnMCfwNvoEUh9CJyYWhkAKARKWMAeQACZGMAeQAFZGMAeQAPZIABZ3JzACECJQIoAuchZXIAoCEgcgAAoKEhaAB2AACg5CoAAWF5MAIzAvIhb24OYRRkbAB0oAciYQCUY3IAAOA12AfdAAFhZkECawIAAWNtRQJnAvIjaXRpY2FsAAJBREdUUAJUAl8CYwJjInV0ZQC0YG8AdAFZAloC2WJiJGxlQWN1dGUA3WJyImF2ZQBgYGkibGRlANxi7yFuZACgxCJmJWVyZW50aWFsRAAAoEYhcAR9AgAAAAAAAIECjgIAABoDZgAA4DXYO91EoagAhQKJAm8AdAAAoNwgcSJ1YWwAAKBQIuIhbGUAA0NETFJVVpkCqAK1Au8C/wIRA28AbgB0AG8AdQByAEkAbgB0AGUAZwByAGEA7ADEAW8AdAKvAgAAAACwAqhgbiNBcnJvdwAAoNMhAAFlb7kC0AJmAHQAgAFBUlQAwQLGAs0CciJyb3cAAKDQIekkZ2h0QXJyb3cAoNQhZQDlACsCbgBnAAABTFLWAugC5SFmdAABQVLcAuECciJyb3cAAKD4J+kkZ2h0QXJyb3cAoPon6SRnaHRBcnJvdwCg+SdpImdodAAAAUFU9gL7AnIicm93AACg0iFlAGUAAKCoInAAQQIGAwAAAAALA3Iicm93AACg0SFvJHduQXJyb3cAAKDVIWUlcnRpY2FsQmFyAACgJSJuAAADQUJMUlRhJAM2AzoDWgNxA3oDciJyb3cAAKGTIUJVLAMwA2EAcgAAoBMpcCNBcnJvdwAAoPUhciJldmUAEWPlIWZ00gJDAwAASwMAAFIDaSVnaHRWZWN0b3IAAKBQKWUkZVZlY3RvcgAAoF4p5SJjdG9yQqC9IWEAcgAAoFYpaSJnaHQA1AFiAwAAaQNlJGVWZWN0b3IAAKBfKeUiY3RvckKgwSFhAHIAAKBXKWUAZQBBoKQiciJyb3cAAKCnIXIAcgBvAPcAtAIAAWN0gwOHA3IA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YwAAoN8i4SFycnCgtiEAoD0pgKIqImJjZG9zACsVMBU6FT4VQRVyImNhcAAAoEgqAAFhdTQVNxVwAACgRipwAACgSipvAHQAAKCNInIAAKBFKgDgKiIA/gACYWxydksVURVuFXMVcgByAG2gtyEAoDwpeQCAAWV2dwBYFWUVaRVxAHACXxUAAAAAYxVyAGUA4wAXFXUA4wAZFWUAZQAAoM4iZSJkZ2UAAKDPImUAbgA7gKQApEBlI2Fycm93AAABbHJ7FX8V5SFmdACgtiFpImdodAAAoLchZQDkAG0VAAFjaYsVkRVvAG4AaQBuAPQAkwFuAHQAAKAxImwiY3R5AACgLSOACUFIYWJjZGVmaGlqbG9yc3R1d3oAuBW7Fb8V1RXgFegV+RUKFhUWHxZUFlcWZRbFFtsW7xb7FgUXChdyAPIAtAJhAHIAAKBlKQACZ2xyc8YVyhXOFdAV5yFlcgCgICDlIXRoAKA4IfIA9QxoAHagECAAoKMiawHZFd4VYSJyb3cAAKAPKWEA4wBfAgABYXnkFecV8iFvbg9hNGQAoUYhYW/tFfQVAAFnciEC8RVyAACgyiF0InNlcQAAoHcqgAFnbG0A/xUCFgUWO4CwALBAdABhALRjcCJ0eXYAAKCxKQABaXIOFhIW8yFodACgfykA4DXYId1hAHIAAAFschsWHRYAoMMhAKDCIYACYWVnc3YAKBauAjYWOhY+Fm0AAKHEIm9zLhY0Fm4AZABzoMQi9SFpdACgZiZhIm1tYQDdY2kAbgAAoPIiAKH3AGlvQxZRFmQAZQAAgfcAO29KFksW90BuI3RpbWVzAACgxyJuAPgAUBZjAHkAUmRjAG8CXhYAAAAAYhZyAG4AAKAeI28AcAAAoA0jgAJscHR1dwBuFnEWdRaSFp4W7CFhciRgZgAA4DXYVd0AotkCZW1wc30WhBaJFo0WcQBkoFAibwB0AACgUSJpIm51cwAAoDgi7CF1cwCgFCLxInVhcmUAoKEiYgBsAGUAYgBhAHIAdwBlAGQAZwDlANcAbgCAAWFkaAClFqoWtBZyAHIAbwD3APUMbwB3AG4AYQByAHIAbwB3APMA8xVhI3Jwb29uAAABbHK8FsAWZQBmAPQAHBZpAGcAaAD0AB4WYgHJFs8WawBhAHIAbwD3AJILbwLUFgAAAADYFnIAbgAAoB8jbwBwAACgDCOAAWNvdADhFukW7BYAAXJ55RboFgDgNdi53FVkbAAAoPYp8iFvaxFhAAFkcvMW9xZvAHQAAKDxImkA5qC/JVsSAAFhaP8WAhdyAPIANQNhAPIA1wvhIm5nbGUAoKYpAAFjaQ4XEBd5AF9k5yJyYXJyAKD/JwAJRGFjZGVmZ2xtbm9wcXJzdHV4MRc4F0YXWxcyBF4XaRd5F40XrBe0F78X2RcVGCEYLRg1GEAYAAFEbzUXgRZvAPQA+BUAAWNzPBdCF3UAdABlADuA6QDpQPQhZXIAoG4qAAJhaW95TRdQF1YXWhfyIW9uG2FyAGOgViI7gOoA6kDsIW9uAKBVIk1kbwB0ABdhAAFEcmIXZhdvAHQAAKBSIgDgNdgi3XKhmipuF3QXYQB2AGUAO4DoAOhAZKCWKm8AdAAAoJgqgKGZKmlscwCAF4UXhxfuInRlcnMAoOcjAKATIWSglSpvAHQAAKCXKoABYXBzAJMXlheiF2MAcgATYXQAeQBzogUinxcAAAAAoRdlAHQAAKAFInAAMaADIDMBqRerFwCgBCAAoAUgAAFnc7AXsRdLYXAAAKACIAABZ3C4F7sXbwBuABlhZgAA4DXYVt2AAWFscwDFF8sXzxdyAHOg1SJsAACg4yl1AHMAAKBxKmkAAKG1A2x21RfYF28AbgC1Y/VjAAJjc3V24BfoF/0XEBgAAWlv5BdWF3IAYwAAoFYiaQLuFwAAAADwF+0ADQThIW50AAFnbPUX+Rd0AHIAAKCWKuUhc3MAoJUqgAFhZWkAAxgGGAoYbABzAD1gcwB0AACgXyJ2AESgYSJEAACgeCrwImFyc2wAoOUpAAFEYRkYHRhvAHQAAKBTInIAcgAAoHEpgAFjZGkAJxgqGO0XcgAAoC8hbwD0AIwCAAFhaDEYMhi3YzuA8ADwQAABbXI5GD0YbAA7gOsA60BvAACgrCCAAWNpcABGGEgYSxhsACFgcwD0ACwEAAFlb08YVxhjAHQAYQB0AGkAbwDuABoEbgBlAG4AdABpAGEAbADlADME4Ql1GAAAgRgAAIMYiBgAAAAAoRilGAAAqhgAALsYvhjRGAAA1xgnGWwAbABpAG4AZwBkAG8AdABzAGUA8QBlF3kARGRtImFsZQAAoEAmgAFpbHIAjRiRGJ0Y7CFpZwCgA/tpApcYAAAAAJoYZwAAoAD7aQBnAACgBPsA4DXYI93sIWlnAKAB++whaWcA4GYAagCAAWFsdACvGLIYthh0AACgbSZpAGcAAKAC+24AcwAAoLElbwBmAJJh8AHCGAAAxhhmAADgNdhX3QABYWvJGMwYbADsAGsEdqDUIgCg2SphI3J0aW50AACgDSoAAWFv2hgiGQABY3PeGB8ZsQPnGP0YBRkSGRUZAAAdGbID7xjyGPQY9xj5GAAA+xg7gL0AvUAAoFMhO4C8ALxAAKBVIQCgWSEAoFshswEBGQAAAxkAoFQhAKBWIbQCCxkOGQAAAAAQGTuAvgC+QACgVyEAoFwhNQAAoFghtgEZGQAAGxkAoFohAKBdITgAAKBeIWwAAKBEIHcAbgAAoCIjYwByAADgNdi73IAIRWFiY2RlZmdpamxub3JzdHYARhlKGVoZXhlmGWkZkhmWGZkZnRmgGa0ZxhnLGc8Z4BkjGmygZyIAoIwqgAFjbXAAUBlTGVgZ9SF0ZfVhbQBhAOSgswM6FgCghipyImV2ZQAfYQABaXliGWUZcgBjAB1hM2RvAHQAIWGAoWUibHFzAMYEcBl6GfGhZSLOBAAAdhlsAGEAbgD0AN8EgKF+KmNkbACBGYQZjBljAACgqSpvAHQAb6CAKmyggioAoIQqZeDbIgD+cwAAoJQqcgAA4DXYJN3noGsirATtIWVsAKA3IWMAeQBTZIChdyJFYWoApxmpGasZAKCSKgCgpSoAoKQqAAJFYWVztBm2Gb0ZwhkAoGkicABwoIoq8iFveACgiipxoIgq8aCIKrUZaQBtAACg5yJwAGYAAOA12FjdYQB2AOUAYwIAAWNp0xnWGXIAAKAKIW0AAKFzImVs3BneGQCgjioAoJAqAIM+ADtjZGxxco0E6xn0GfgZ/BkBGgABY2nvGfEZAKCnKnIAAKB6Km8AdAAAoNci0CFhcgCglSl1ImVzdAAAoHwqgAJhZGVscwAKGvQZFhrVBCAa8AEPGgAAFBpwAHIAbwD4AFkZcgAAoHgpcQAAAWxxxAQbGmwAZQBzAPMASRlpAO0A5AQAAWVuJxouGnIjdG5lcXEAAOBpIgD+xQAsGgAFQWFiY2Vma29zeUAaQxpmGmoabRqDGocalhrCGtMacgDyAMwCAAJpbG1yShpOGlAaVBpyAHMA8ABxD2YAvWBpAGwA9AASBQABZHJYGlsaYwB5AEpkAKGUIWN3YBpkGmkAcgAAoEgpAKCtIWEAcgAAoA8h6SFyYyVhgAFhbHIAcxp7Gn8a8iF0c3WgZSZpAHQAAKBlJuwhaXAAoCYg4yFvbgCguSJyAADgNdgl3XMAAAFld4wakRphInJvdwAAoCUpYSJyb3cAAKAmKYACYW1vcHIAnxqjGqcauhq+GnIAcgAAoP8h9CFodACgOyJrAAABbHKsGrMaZSRmdGFycm93AACgqSHpJGdodGFycm93AKCqIWYAAOA12Fnd4iFhcgCgFSCAAWNsdADIGswa0BpyAADgNdi93GEAcwDoAGka8iFvaydhAAFicNca2xr1IWxsAKBDIOghZW4AoBAg4Qr2GgAA/RoAAAgbExsaGwAAIRs7GwAAAAA+G2IbmRuVG6sbAACyG80b0htjAHUAdABlADuA7QDtQAChYyBpeQEbBhtyAGMAO4DuAO5AOGQAAWN4CxsNG3kANWRjAGwAO4ChAKFAAAFmcssCFhsA4DXYJt1yAGEAdgBlADuA7ADsQIChSCFpbm8AJxsyGzYbAAFpbisbLxtuAHQAAKAMKnQAAKAtIuYhaW4AoNwpdABhAACgKSHsIWlnM2GAAWFvcABDG1sbXhuAAWNndABJG0sbWRtyACthgAFlbHAAcQVRG1UbaQBuAOUAyAVhAHIA9AByBWgAMWFmAACgtyJlAGQAtWEAoggiY2ZvdGkbbRt1G3kb4SFyZQCgBSFpAG4AdKAeImkAZQAAoN0pZABvAPQAWxsAoisiY2VscIEbhRuPG5QbYQBsAACguiIAAWdyiRuNG2UAcgDzACMQ4wCCG2EicmhrAACgFyryIW9kAKA8KgACY2dwdJ8boRukG6gbeQBRZG8AbgAvYWYAAOA12FrdYQC5Y3UAZQBzAHQAO4C/AL9AAAFjabUbuRtyAADgNdi+3G4AAKIIIkVkc3bCG8QbyBvQAwCg+SJvAHQAAKD1Inag9CIAoPMiaaBiIOwhZGUpYesB1hsAANkbYwB5AFZkbAA7gO8A70AAA2NmbW9zdeYb7hvyG/Ub+hsFHAABaXnqG+0bcgBjADVhOWRyAADgNdgn3eEhdGg3YnAAZgAA4DXYW93jAf8bAAADHHIAAOA12L/c8iFjeVhk6yFjeVRkAARhY2ZnaGpvcxUcGhwiHCYcKhwtHDAcNRzwIXBhdqC6A/BjAAFleR4cIRzkIWls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ZmdobG1vcHJzdHV3CiwNLBEsHSwnLDEsQCxLLFIsYix6LIQsjyzLLOgs7Sz/LAotcgDyAAkDYQByAACgYykAAWNyFSwbLHUAdABlADuA+gD6QPIACQ1yAOMBIywAACUseQBeZHYAZQBtYQABaXkrLDAscgBjADuA+wD7QENkgAFhYmgANyw6LD0scgDyANEO7CFhY3FhYQDyAOAOAAFpckQsSCzzIWh0AKB+KQDgNdgy3XIAYQB2AGUAO4D5APlAYQFWLF8scgAAAWxyWixcLACgvyEAoL4hbABrAACggCUAAWN0Zix2LG8CbCwAAAAAcyxyAG4AZaAcI3IAAKAcI28AcAAAoA8jcgBpAACg+CUAAWFsfiyBLGMAcgBrYTuAqACoQAABZ3CILIssbwBuAHNhZgAA4DXYZt0AA2FkaGxzdZksniynLLgsuyzFLHIAcgBvAPcACQ1vAHcAbgBhAHIAcgBvAPcA2A5hI3Jwb29uAAABbHKvLLMsZQBmAPQAWyxpAGcAaAD0AF0sdQDzAKYOaQAAocUDaGzBLMIs0mNvAG4AxWPwI2Fycm93cwCgyCGAAWNpdADRLOEs5CxvAtcsAAAAAN4scgBuAGWgHSNyAACgHSNvAHAAAKAOI24AZwBvYXIAaQAAoPklYwByAADgNdjK3IABZGlyAPMs9yz6LG8AdAAAoPAi7CFkZWlhaQBmoLUlAKC0JQABYW0DLQYtcgDyAMosbAA7gPwA/EDhIm5nbGUAoKcpgAdBQkRhY2RlZmxub3Byc3oAJy0qLTAtNC2bLZ0toS2/LcMtxy3TLdgt3C3gLfwtcgDyABADYQByAHag6CoAoOkqYQBzAOgA/gIAAW5yOC08LechcnQAoJwpgANla25wcnN0AJkpSC1NLVQtXi1iLYItYQBwAHAA4QAaHG8AdABoAGkAbgDnAKEXgAFoaXIAoSmzJFotbwBwAPQAdCVooJUh7wD4JgABaXVmLWotZwBtAOEAuygAAWJwbi14LXMjZXRuZXEAceCKIgD+AODLKgD+cyNldG5lcQBx4IsiAP4A4MwqAP4AAWhyhi2KLWUAdADhABIraSNhbmdsZQAAAWxyki2WLeUhZnQAoLIiaSJnaHQAAKCzInkAMmThIXNoAKCiIoABZWxyAKcttC24LWKiKCKuLQAAAACyLWEAcgAAoLsicQAAoFoi7CFpcACg7iIAAWJ0vC1eD2EA8gBfD3IAAOA12DPddAByAOkAlS1zAHUAAAFicM0t0C0A4IIi0iAA4IMi0iBwAGYAAOA12GfdcgBvAPAAWQt0AHIA6QCaLQABY3XkLegtcgAA4DXYy9wAAWJw7C30LW4AAAFFZXUt8S0A4IoiAP5uAAABRWV/LfktAOCLIgD+6SJnemFnAKCaKYADY2Vmb3BycwANLhAuJS4pLiMuLi40LukhcmN1YQABZGkULiEuAAFiZxguHC5hAHIAAKBfKmUAcaAnIgCgWSLlIXJwAKAYIXIAAOA12DTdcABmAADgNdho3WWgQCJhAHQA6ABqD2MAcgAA4DXYzNzjCuQRUC4AAFQuAABYLmIuAAAAAGMubS5wLnQuAAAAAIguki4AAJouJxIqEnQAcgDpAB0ScgAA4DXYNd0AAUFhWy5eLnIA8gDnAnIA8gCTB75jAAFBYWYuaS5yAPIA4AJyAPIAjAdhAPAAeh5pAHMAAKD7IoABZHB0APgReS6DLgABZmx9LoAuAOA12GnddQDzAP8RaQBtAOUABBIAAUFhiy6OLnIA8gDuAnIA8gCaBwABY3GVLgoScgAA4DXYzdwAAXB0nS6hLmwAdQDzACUScgDpACASAARhY2VmaW9zdbEuvC7ELsguzC7PLtQu2S5jAAABdXm2LrsudABlADuA/QD9QE9kAAFpecAuwy5yAGMAd2FLZG4AO4ClAKVAcgAA4DXYNt1jAHkAV2RwAGYAAOA12GrdYwByAADgNdjO3AABY23dLt8ueQBOZGwAO4D/AP9AAAVhY2RlZmhpb3N38y73Lv8uAi8MLxAvEy8YLx0vIi9jInV0ZQB6YQABYXn7Lv4u8iFvbn5hN2RvAHQAfGEAAWV0Bi8KL3QAcgDmAB8QYQC2Y3IAAOA12DfdYwB5ADZk5yJyYXJyAKDdIXAAZgAA4DXYa91jAHIAAOA12M/cAAFqbiYvKC8AoA0gagAAoAwg"),gd=yr("AAJhZ2xxBwARABMAFQBtAg0AAAAAAA8AcAAmYG8AcwAnYHQAPmB0ADxg9SFvdCJg");var J;(function(e){e[e.VALUE_LENGTH=49152]="VALUE_LENGTH",e[e.FLAG13=8192]="FLAG13",e[e.BRANCH_LENGTH=8064]="BRANCH_LENGTH",e[e.JUMP_TABLE=127]="JUMP_TABLE"})(J||(J={}));var Q;(function(e){e[e.NUM=35]="NUM",e[e.SEMI=59]="SEMI",e[e.EQUALS=61]="EQUALS",e[e.ZERO=48]="ZERO",e[e.NINE=57]="NINE",e[e.LOWER_A=97]="LOWER_A",e[e.LOWER_F=102]="LOWER_F",e[e.LOWER_X=120]="LOWER_X",e[e.LOWER_Z=122]="LOWER_Z",e[e.UPPER_A=65]="UPPER_A",e[e.UPPER_F=70]="UPPER_F",e[e.UPPER_Z=90]="UPPER_Z"})(Q||(Q={}));const vr=32;function $t(e){return e>=Q.ZERO&&e<=Q.NINE}function wd(e){return e>=Q.UPPER_A&&e<=Q.UPPER_F||e>=Q.LOWER_A&&e<=Q.LOWER_F}function bd(e){return e>=Q.UPPER_A&&e<=Q.UPPER_Z||e>=Q.LOWER_A&&e<=Q.LOWER_Z||$t(e)}function yd(e){return e===Q.EQUALS||bd(e)}var z;(function(e){e[e.EntityStart=0]="EntityStart",e[e.NumericStart=1]="NumericStart",e[e.NumericDecimal=2]="NumericDecimal",e[e.NumericHex=3]="NumericHex",e[e.NamedEntity=4]="NamedEntity"})(z||(z={}));var X;(function(e){e[e.Legacy=0]="Legacy",e[e.Strict=1]="Strict",e[e.Attribute=2]="Attribute"})(X||(X={}));class vd{decodeTree;emitCodePoint;errors;constructor(t,n,i){this.decodeTree=t,this.emitCodePoint=n,this.errors=i}state=z.EntityStart;consumed=1;result=0;treeIndex=0;excess=1;decodeMode=X.Strict;runConsumed=0;startEntity(t){this.decodeMode=t,this.state=z.EntityStart,this.result=0,this.treeIndex=0,this.excess=1,this.consumed=1,this.runConsumed=0}write(t,n){switch(this.state){case z.EntityStart:return t.charCodeAt(n)===Q.NUM?(this.state=z.NumericStart,this.consumed+=1,this.stateNumericStart(t,n+1)):(this.state=z.NamedEntity,this.stateNamedEntity(t,n));case z.NumericStart:return this.stateNumericStart(t,n);case z.NumericDecimal:return this.stateNumericDecimal(t,n);case z.NumericHex:return this.stateNumericHex(t,n);case z.NamedEntity:return this.stateNamedEntity(t,n)}}stateNumericStart(t,n){return n>=t.length?-1:(t.charCodeAt(n)|vr)===Q.LOWER_X?(this.state=z.NumericHex,this.consumed+=1,this.stateNumericHex(t,n+1)):(this.state=z.NumericDecimal,this.stateNumericDecimal(t,n))}stateNumericHex(t,n){for(;n<t.length;){const i=t.charCodeAt(n);if($t(i)||wd(i)){const r=i<=Q.NINE?i-Q.ZERO:(i|vr)-Q.LOWER_A+10;this.result=this.result*16+r,this.consumed++,n++}else return this.emitNumericEntity(i,3)}return-1}stateNumericDecimal(t,n){for(;n<t.length;){const i=t.charCodeAt(n);if($t(i))this.result=this.result*10+(i-Q.ZERO),this.consumed++,n++;else return this.emitNumericEntity(i,2)}return-1}emitNumericEntity(t,n){if(this.consumed<=n)return this.errors?.absenceOfDigitsInNumericCharacterReference(this.consumed),0;if(t===Q.SEMI)this.consumed+=1;else if(this.decodeMode===X.Strict)return 0;return this.emitCodePoint(pd(this.result),this.consumed),this.errors&&(t!==Q.SEMI&&this.errors.missingSemicolonAfterCharacterReference(),this.errors.validateNumericCharacterReference(this.result)),this.consumed}stateNamedEntity(t,n){const{decodeTree:i}=this;let r=i[this.treeIndex],s=(r&J.VALUE_LENGTH)>>14;for(;n<t.length;){if(s===0&&(r&J.FLAG13)!==0){const c=(r&J.BRANCH_LENGTH)>>7;if(this.runConsumed===0){const l=r&J.JUMP_TABLE;if(t.charCodeAt(n)!==l)return this.result===0?0:this.emitNotTerminatedNamedEntity();n++,this.excess++,this.runConsumed++}for(;this.runConsumed<c;){if(n>=t.length)return-1;const l=this.runConsumed-1,A=i[this.treeIndex+1+(l>>1)],m=l%2===0?A&255:A>>8&255;if(t.charCodeAt(n)!==m)return this.runConsumed=0,this.result===0?0:this.emitNotTerminatedNamedEntity();n++,this.excess++,this.runConsumed++}this.runConsumed=0,this.treeIndex+=1+(c>>1),r=i[this.treeIndex],s=(r&J.VALUE_LENGTH)>>14}if(n>=t.length)break;const o=t.charCodeAt(n);if(o===Q.SEMI&&s!==0&&(r&J.FLAG13)!==0)return this.emitNamedEntityData(this.treeIndex,s,this.consumed+this.excess);if(this.treeIndex=kd(i,r,this.treeIndex+Math.max(1,s),o),this.treeIndex<0)return this.result===0||this.decodeMode===X.Attribute&&(s===0||yd(o))?0:this.emitNotTerminatedNamedEntity();if(r=i[this.treeIndex],s=(r&J.VALUE_LENGTH)>>14,s!==0){if(o===Q.SEMI)return this.emitNamedEntityData(this.treeIndex,s,this.consumed+this.excess);this.decodeMode!==X.Strict&&(r&J.FLAG13)===0&&(this.result=this.treeIndex,this.consumed+=this.excess,this.excess=0)}n++,this.excess++}return-1}emitNotTerminatedNamedEntity(){const{result:t,decodeTree:n}=this,i=(n[t]&J.VALUE_LENGTH)>>14;return this.emitNamedEntityData(t,i,this.consumed),this.errors?.missingSemicolonAfterCharacterReference(),this.consumed}emitNamedEntityData(t,n,i){const{decodeTree:r}=this;return this.emitCodePoint(n===1?r[t]&~(J.VALUE_LENGTH|J.FLAG13):r[t+1],i),n===3&&this.emitCodePoint(r[t+2],i),i}end(){switch(this.state){case z.NamedEntity:return this.result!==0&&(this.decodeMode!==X.Attribute||this.result===this.treeIndex)?this.emitNotTerminatedNamedEntity():0;case z.NumericDecimal:return this.emitNumericEntity(0,2);case z.NumericHex:return this.emitNumericEntity(0,3);case z.NumericStart:return this.errors?.absenceOfDigitsInNumericCharacterReference(this.consumed),0;case z.EntityStart:return 0}}}function kd(e,t,n,i){const r=(t&J.BRANCH_LENGTH)>>7,s=t&J.JUMP_TABLE;if(r===0)return s!==0&&i===s?n:-1;if(s){const A=i-s;return A<0||A>=r?-1:e[n+A]-1}const o=r+1>>1;let c=0,l=r-1;for(;c<=l;){const A=c+l>>>1,m=A>>1,I=e[n+m]>>(A&1)*8&255;if(I<i)c=A+1;else if(I>i)l=A-1;else return e[n+o+A]}return-1}var x;(function(e){e[e.Tab=9]="Tab",e[e.NewLine=10]="NewLine",e[e.FormFeed=12]="FormFeed",e[e.CarriageReturn=13]="CarriageReturn",e[e.Space=32]="Space",e[e.ExclamationMark=33]="ExclamationMark",e[e.Number=35]="Number",e[e.Amp=38]="Amp",e[e.SingleQuote=39]="SingleQuote",e[e.DoubleQuote=34]="DoubleQuote",e[e.Dash=45]="Dash",e[e.Slash=47]="Slash",e[e.Zero=48]="Zero",e[e.Nine=57]="Nine",e[e.Semi=59]="Semi",e[e.Lt=60]="Lt",e[e.Eq=61]="Eq",e[e.Gt=62]="Gt",e[e.Questionmark=63]="Questionmark",e[e.UpperA=65]="UpperA",e[e.LowerA=97]="LowerA",e[e.UpperF=70]="UpperF",e[e.LowerF=102]="LowerF",e[e.UpperZ=90]="UpperZ",e[e.LowerZ=122]="LowerZ",e[e.LowerX=120]="LowerX",e[e.OpeningSquareBracket=91]="OpeningSquareBracket"})(x||(x={}));var h;(function(e){e[e.Text=1]="Text",e[e.BeforeTagName=2]="BeforeTagName",e[e.InTagName=3]="InTagName",e[e.InSelfClosingTag=4]="InSelfClosingTag",e[e.BeforeClosingTagName=5]="BeforeClosingTagName",e[e.InClosingTagName=6]="InClosingTagName",e[e.AfterClosingTagName=7]="AfterClosingTagName",e[e.BeforeAttributeName=8]="BeforeAttributeName",e[e.InAttributeName=9]="InAttributeName",e[e.AfterAttributeName=10]="AfterAttributeName",e[e.BeforeAttributeValue=11]="BeforeAttributeValue",e[e.InAttributeValueDq=12]="InAttributeValueDq",e[e.InAttributeValueSq=13]="InAttributeValueSq",e[e.InAttributeValueNq=14]="InAttributeValueNq",e[e.BeforeDeclaration=15]="BeforeDeclaration",e[e.InDeclaration=16]="InDeclaration",e[e.InProcessingInstruction=17]="InProcessingInstruction",e[e.BeforeComment=18]="BeforeComment",e[e.CDATASequence=19]="CDATASequence",e[e.DeclarationSequence=20]="DeclarationSequence",e[e.InSpecialComment=21]="InSpecialComment",e[e.InCommentLike=22]="InCommentLike",e[e.SpecialStartSequence=23]="SpecialStartSequence",e[e.InSpecialTag=24]="InSpecialTag",e[e.InPlainText=25]="InPlainText",e[e.InEntity=26]="InEntity"})(h||(h={}));function me(e){return e===x.Space||e===x.NewLine||e===x.Tab||e===x.FormFeed||e===x.CarriageReturn}function Ne(e){return e===x.Slash||e===x.Gt||me(e)}function Id(e){return e>=x.LowerA&&e<=x.LowerZ||e>=x.UpperA&&e<=x.UpperZ}var $;(function(e){e[e.NoValue=0]="NoValue",e[e.Unquoted=1]="Unquoted",e[e.Single=2]="Single",e[e.Double=3]="Double"})($||($={}));const C={Empty:new Uint8Array(0),Cdata:new Uint8Array([67,68,65,84,65,91]),CdataEnd:new Uint8Array([93,93,62]),CommentEnd:new Uint8Array([45,45,33,62]),Doctype:new Uint8Array([100,111,99,116,121,112,101]),IframeEnd:new Uint8Array([60,47,105,102,114,97,109,101]),NoembedEnd:new Uint8Array([60,47,110,111,101,109,98,101,100]),NoframesEnd:new Uint8Array([60,47,110,111,102,114,97,109,101,115]),Plaintext:new Uint8Array([60,47,112,108,97,105,110,116,101,120,116]),ScriptEnd:new Uint8Array([60,47,115,99,114,105,112,116]),StyleEnd:new Uint8Array([60,47,115,116,121,108,101]),TitleEnd:new Uint8Array([60,47,116,105,116,108,101]),TextareaEnd:new Uint8Array([60,47,116,101,120,116,97,114,101,97]),XmpEnd:new Uint8Array([60,47,120,109,112])},xd=new Map([[C.IframeEnd[2],C.IframeEnd],[C.NoembedEnd[2],C.NoembedEnd],[C.Plaintext[2],C.Plaintext],[C.ScriptEnd[2],C.ScriptEnd],[C.TitleEnd[2],C.TitleEnd],[C.XmpEnd[2],C.XmpEnd]]);class Sd{cbs;state=h.Text;buffer="";sectionStart=0;index=0;entityStart=0;baseState=h.Text;isSpecial=!1;running=!0;offset=0;xmlMode;decodeEntities;recognizeSelfClosing;entityDecoder;constructor({xmlMode:t=!1,decodeEntities:n=!0,recognizeSelfClosing:i=t},r){this.cbs=r,this.xmlMode=t,this.decodeEntities=n,this.recognizeSelfClosing=i,this.entityDecoder=new vd(t?gd:md,(s,o)=>this.emitCodePoint(s,o))}reset(){this.state=h.Text,this.buffer="",this.sectionStart=0,this.index=0,this.baseState=h.Text,this.isSpecial=!1,this.currentSequence=C.Empty,this.sequenceIndex=0,this.running=!0,this.offset=0}write(t){this.offset+=this.buffer.length,this.buffer=t,this.parse()}end(){this.running&&this.finish()}pause(){this.running=!1}resume(){this.running=!0,this.index<this.buffer.length+this.offset&&this.parse()}stateText(t){t===x.Lt||!this.decodeEntities&&this.fastForwardTo(x.Lt)?(this.index>this.sectionStart&&this.cbs.ontext(this.sectionStart,this.index),this.state=h.BeforeTagName,this.sectionStart=this.index):this.decodeEntities&&t===x.Amp&&this.startEntity()}currentSequence=C.Empty;sequenceIndex=0;enterTagBody(){this.currentSequence===C.Plaintext?(this.currentSequence=C.Empty,this.state=h.InPlainText):this.isSpecial?(this.state=h.InSpecialTag,this.sequenceIndex=0):this.state=h.Text}stateSpecialStartSequence(t){const n=t|32;if(this.sequenceIndex<this.currentSequence.length){if(n===this.currentSequence[this.sequenceIndex]){this.sequenceIndex++;return}if(this.sequenceIndex===3){if(this.currentSequence===C.ScriptEnd&&n===C.StyleEnd[3]){this.currentSequence=C.StyleEnd,this.sequenceIndex=4;return}if(this.currentSequence===C.TitleEnd&&n===C.TextareaEnd[3]){this.currentSequence=C.TextareaEnd,this.sequenceIndex=4;return}}else if(this.sequenceIndex===4&&this.currentSequence===C.NoembedEnd&&n===C.NoframesEnd[4]){this.currentSequence=C.NoframesEnd,this.sequenceIndex=5;return}}else if(Ne(t)){this.sequenceIndex=0,this.state=h.InTagName,this.stateInTagName(t);return}this.isSpecial=!1,this.currentSequence=C.Empty,this.sequenceIndex=0,this.state=h.InTagName,this.stateInTagName(t)}stateCDATASequence(t){t===C.Cdata[this.sequenceIndex]?++this.sequenceIndex===C.Cdata.length&&(this.state=h.InCommentLike,this.currentSequence=C.CdataEnd,this.sequenceIndex=0,this.sectionStart=this.index+1):(this.sequenceIndex=0,this.xmlMode?(this.state=h.InDeclaration,this.stateInDeclaration(t)):(this.state=h.InSpecialComment,this.stateInSpecialComment(t)))}fastForwardTo(t){for(;++this.index<this.buffer.length+this.offset;)if(this.buffer.charCodeAt(this.index-this.offset)===t)return!0;return this.index=this.buffer.length+this.offset-1,!1}emitComment(t){this.cbs.oncomment(this.sectionStart,this.index,t),this.sequenceIndex=0,this.sectionStart=this.index+1,this.state=h.Text}stateInCommentLike(t){!this.xmlMode&&this.currentSequence===C.CommentEnd&&this.sequenceIndex<=1&&this.index===this.sectionStart+this.sequenceIndex&&t===x.Gt?this.emitComment(this.sequenceIndex):this.currentSequence===C.CommentEnd&&this.sequenceIndex===2&&t===x.Gt?this.emitComment(2):this.currentSequence===C.CommentEnd&&this.sequenceIndex===this.currentSequence.length-1&&t!==x.Gt?this.sequenceIndex=+(t===x.Dash):t===this.currentSequence[this.sequenceIndex]?++this.sequenceIndex===this.currentSequence.length&&(this.currentSequence===C.CdataEnd?this.cbs.oncdata(this.sectionStart,this.index,2):this.cbs.oncomment(this.sectionStart,this.index,3),this.sequenceIndex=0,this.sectionStart=this.index+1,this.state=h.Text):this.sequenceIndex===0?this.fastForwardTo(this.currentSequence[0])&&(this.sequenceIndex=1):t!==this.currentSequence[this.sequenceIndex-1]&&(this.sequenceIndex=0)}isTagStartChar(t){return this.xmlMode?!Ne(t):Id(t)}stateInSpecialTag(t){if(this.sequenceIndex===this.currentSequence.length){if(Ne(t)){const n=this.index-this.currentSequence.length;if(this.sectionStart<n){const i=this.index;this.index=n,this.cbs.ontext(this.sectionStart,n),this.index=i}this.isSpecial=!1,this.sectionStart=n+2,this.stateInClosingTagName(t);return}this.sequenceIndex=0}(t|32)===this.currentSequence[this.sequenceIndex]?this.sequenceIndex+=1:this.sequenceIndex===0?this.currentSequence===C.TitleEnd||this.currentSequence===C.TextareaEnd?this.decodeEntities&&t===x.Amp&&this.startEntity():this.fastForwardTo(x.Lt)&&(this.sequenceIndex=1):this.sequenceIndex=+(t===x.Lt)}stateBeforeTagName(t){if(t===x.ExclamationMark)this.state=h.BeforeDeclaration,this.sectionStart=this.index+1;else if(t===x.Questionmark)this.xmlMode?(this.state=h.InProcessingInstruction,this.sequenceIndex=0,this.sectionStart=this.index+1):(this.state=h.InSpecialComment,this.sectionStart=this.index);else if(this.isTagStartChar(t)){this.sectionStart=this.index;const n=this.xmlMode||this.cbs.isInForeignContext?.()?void 0:xd.get(t|32);n===void 0?this.state=h.InTagName:(this.isSpecial=!0,this.currentSequence=n,this.sequenceIndex=3,this.state=h.SpecialStartSequence)}else t===x.Slash?this.state=h.BeforeClosingTagName:(this.state=h.Text,this.stateText(t))}stateInTagName(t){Ne(t)&&(this.cbs.onopentagname(this.sectionStart,this.index),this.sectionStart=-1,this.state=h.BeforeAttributeName,this.stateBeforeAttributeName(t))}stateBeforeClosingTagName(t){me(t)?this.xmlMode||(this.state=h.InSpecialComment,this.sectionStart=this.index):t===x.Gt?(this.state=h.Text,this.xmlMode||(this.sectionStart=this.index+1)):(this.state=this.isTagStartChar(t)?h.InClosingTagName:h.InSpecialComment,this.sectionStart=this.index)}stateInClosingTagName(t){Ne(t)&&(this.cbs.onclosetag(this.sectionStart,this.index),this.sectionStart=-1,this.state=h.AfterClosingTagName,this.stateAfterClosingTagName(t))}stateAfterClosingTagName(t){(t===x.Gt||this.fastForwardTo(x.Gt))&&(this.state=h.Text,this.sectionStart=this.index+1)}stateBeforeAttributeName(t){t===x.Gt?(this.cbs.onopentagend(this.index),this.enterTagBody(),this.sectionStart=this.index+1):t===x.Slash?this.state=h.InSelfClosingTag:me(t)||(this.state=h.InAttributeName,this.sectionStart=this.index)}stateInSelfClosingTag(t){if(t===x.Gt){if(this.cbs.onselfclosingtag(this.index),this.sectionStart=this.index+1,!this.recognizeSelfClosing){this.enterTagBody();return}this.state=h.Text,this.isSpecial=!1,this.currentSequence=C.Empty}else me(t)||(this.state=h.BeforeAttributeName,this.stateBeforeAttributeName(t))}stateInAttributeName(t){(t===x.Eq||Ne(t))&&(this.cbs.onattribname(this.sectionStart,this.index),this.sectionStart=this.index,this.state=h.AfterAttributeName,this.stateAfterAttributeName(t))}stateAfterAttributeName(t){t===x.Eq?this.state=h.BeforeAttributeValue:t===x.Slash||t===x.Gt?(this.cbs.onattribend($.NoValue,this.sectionStart),this.sectionStart=-1,this.state=h.BeforeAttributeName,this.stateBeforeAttributeName(t)):me(t)||(this.cbs.onattribend($.NoValue,this.sectionStart),this.state=h.InAttributeName,this.sectionStart=this.index)}stateBeforeAttributeValue(t){t===x.DoubleQuote?(this.state=h.InAttributeValueDq,this.sectionStart=this.index+1):t===x.SingleQuote?(this.state=h.InAttributeValueSq,this.sectionStart=this.index+1):me(t)||(this.sectionStart=this.index,this.state=h.InAttributeValueNq,this.stateInAttributeValueNoQuotes(t))}handleInAttributeValue(t,n){t===n||!this.decodeEntities&&this.fastForwardTo(n)?(this.cbs.onattribdata(this.sectionStart,this.index),this.sectionStart=-1,this.cbs.onattribend(n===x.DoubleQuote?$.Double:$.Single,this.index+1),this.state=h.BeforeAttributeName):this.decodeEntities&&t===x.Amp&&this.startEntity()}stateInAttributeValueDoubleQuotes(t){this.handleInAttributeValue(t,x.DoubleQuote)}stateInAttributeValueSingleQuotes(t){this.handleInAttributeValue(t,x.SingleQuote)}stateInAttributeValueNoQuotes(t){me(t)||t===x.Gt?(this.cbs.onattribdata(this.sectionStart,this.index),this.sectionStart=-1,this.cbs.onattribend($.Unquoted,this.index),this.state=h.BeforeAttributeName,this.stateBeforeAttributeName(t)):this.decodeEntities&&t===x.Amp&&this.startEntity()}stateBeforeDeclaration(t){t===x.OpeningSquareBracket?(this.state=h.CDATASequence,this.sequenceIndex=0):this.xmlMode?this.state=t===x.Dash?h.BeforeComment:h.InDeclaration:(t|32)===C.Doctype[0]?(this.state=h.DeclarationSequence,this.currentSequence=C.Doctype,this.sequenceIndex=1):t===x.Gt?(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=h.Text,this.sectionStart=this.index+1):t===x.Dash?this.state=h.BeforeComment:this.state=h.InSpecialComment}stateDeclarationSequence(t){this.sequenceIndex===this.currentSequence.length?(this.state=h.InDeclaration,this.stateInDeclaration(t)):(t|32)===this.currentSequence[this.sequenceIndex]?this.sequenceIndex+=1:t===x.Gt?(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=h.Text,this.sectionStart=this.index+1):this.state=h.InSpecialComment}stateInDeclaration(t){(t===x.Gt||this.fastForwardTo(x.Gt))&&(this.cbs.ondeclaration(this.sectionStart,this.index),this.state=h.Text,this.sectionStart=this.index+1)}stateInProcessingInstruction(t){t===x.Questionmark?this.sequenceIndex=1:t===x.Gt&&this.sequenceIndex===1?(this.cbs.onprocessinginstruction(this.sectionStart,this.index-1),this.sequenceIndex=0,this.state=h.Text,this.sectionStart=this.index+1):this.sequenceIndex=Number(this.fastForwardTo(x.Questionmark))}stateBeforeComment(t){t===x.Dash?(this.state=h.InCommentLike,this.currentSequence=C.CommentEnd,this.sequenceIndex=0,this.sectionStart=this.index+1):this.xmlMode?this.state=h.InDeclaration:t===x.Gt?(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=h.Text,this.sectionStart=this.index+1):this.state=h.InSpecialComment}stateInSpecialComment(t){(t===x.Gt||this.fastForwardTo(x.Gt))&&(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=h.Text,this.sectionStart=this.index+1)}startEntity(){this.baseState=this.state,this.state=h.InEntity,this.entityStart=this.index,this.entityDecoder.startEntity(this.xmlMode?X.Strict:this.baseState===h.Text||this.baseState===h.InSpecialTag?X.Legacy:X.Attribute)}stateInEntity(){const t=this.index-this.offset,n=this.entityDecoder.write(this.buffer,t);if(n>=0)this.state=this.baseState,n===0&&(this.index-=1);else{if(t<this.buffer.length&&this.buffer.charCodeAt(t)===x.Amp){this.state=this.baseState,this.index-=1;return}this.index=this.offset+this.buffer.length-1}}cleanup(){this.running&&this.sectionStart!==this.index&&(this.state===h.Text||this.state===h.InPlainText||this.state===h.InSpecialTag&&this.sequenceIndex===0?(this.cbs.ontext(this.sectionStart,this.index),this.sectionStart=this.index):(this.state===h.InAttributeValueDq||this.state===h.InAttributeValueSq||this.state===h.InAttributeValueNq)&&(this.cbs.onattribdata(this.sectionStart,this.index),this.sectionStart=this.index))}shouldContinue(){return this.index<this.buffer.length+this.offset&&this.running}parse(){for(;this.shouldContinue();){const t=this.buffer.charCodeAt(this.index-this.offset);switch(this.state){case h.Text:{this.stateText(t);break}case h.InPlainText:{this.index=this.buffer.length+this.offset-1;break}case h.SpecialStartSequence:{this.stateSpecialStartSequence(t);break}case h.InSpecialTag:{this.stateInSpecialTag(t);break}case h.CDATASequence:{this.stateCDATASequence(t);break}case h.DeclarationSequence:{this.stateDeclarationSequence(t);break}case h.InAttributeValueDq:{this.stateInAttributeValueDoubleQuotes(t);break}case h.InAttributeName:{this.stateInAttributeName(t);break}case h.InCommentLike:{this.stateInCommentLike(t);break}case h.InSpecialComment:{this.stateInSpecialComment(t);break}case h.BeforeAttributeName:{this.stateBeforeAttributeName(t);break}case h.InTagName:{this.stateInTagName(t);break}case h.InClosingTagName:{this.stateInClosingTagName(t);break}case h.BeforeTagName:{this.stateBeforeTagName(t);break}case h.AfterAttributeName:{this.stateAfterAttributeName(t);break}case h.InAttributeValueSq:{this.stateInAttributeValueSingleQuotes(t);break}case h.BeforeAttributeValue:{this.stateBeforeAttributeValue(t);break}case h.BeforeClosingTagName:{this.stateBeforeClosingTagName(t);break}case h.AfterClosingTagName:{this.stateAfterClosingTagName(t);break}case h.InAttributeValueNq:{this.stateInAttributeValueNoQuotes(t);break}case h.InSelfClosingTag:{this.stateInSelfClosingTag(t);break}case h.InDeclaration:{this.stateInDeclaration(t);break}case h.BeforeDeclaration:{this.stateBeforeDeclaration(t);break}case h.BeforeComment:{this.stateBeforeComment(t);break}case h.InProcessingInstruction:{this.stateInProcessingInstruction(t);break}case h.InEntity:{this.stateInEntity();break}}this.index++}this.cleanup()}finish(){this.state===h.InEntity&&(this.entityDecoder.end(),this.state=this.baseState),this.handleTrailingData(),this.cbs.onend()}handleTrailingCommentLikeData(t){if(this.state!==h.InCommentLike)return!1;if(this.currentSequence===C.CdataEnd)if(this.xmlMode)this.sectionStart<t&&this.cbs.oncdata(this.sectionStart,t,0);else{const n=this.sectionStart-C.Cdata.length-1;this.cbs.oncomment(n,t,0)}else{const n=this.xmlMode?0:Math.min(this.sequenceIndex,C.CommentEnd.length-1);this.cbs.oncomment(this.sectionStart,t,n)}return!0}handleTrailingMarkupDeclaration(t){if(this.xmlMode)switch(this.state){case h.InSpecialComment:case h.BeforeComment:case h.CDATASequence:case h.DeclarationSequence:case h.InDeclaration:return this.cbs.ontext(this.sectionStart,t),!0;default:return!1}switch(this.state){case h.BeforeDeclaration:case h.InSpecialComment:case h.BeforeComment:case h.CDATASequence:return this.cbs.oncomment(this.sectionStart,t,0),!0;case h.DeclarationSequence:return this.sequenceIndex!==C.Doctype.length&&this.cbs.oncomment(this.sectionStart,t,0),!0;case h.InDeclaration:return!0;default:return!1}}handleTrailingData(){const t=this.buffer.length+this.offset;if(!(this.handleTrailingCommentLikeData(t)||this.handleTrailingMarkupDeclaration(t))&&!(this.sectionStart>=t))switch(this.state){case h.InTagName:case h.BeforeAttributeName:case h.BeforeAttributeValue:case h.AfterAttributeName:case h.InAttributeName:case h.InAttributeValueSq:case h.InAttributeValueDq:case h.InAttributeValueNq:case h.InClosingTagName:break;default:this.cbs.ontext(this.sectionStart,t)}}emitCodePoint(t,n){this.baseState!==h.Text&&this.baseState!==h.InSpecialTag?(this.sectionStart<this.entityStart&&this.cbs.onattribdata(this.sectionStart,this.entityStart),this.sectionStart=this.entityStart+n,this.index=this.sectionStart-1,this.cbs.onattribentity(t)):(this.sectionStart<this.entityStart&&this.cbs.ontext(this.sectionStart,this.entityStart),this.sectionStart=this.entityStart+n,this.index=this.sectionStart-1,this.cbs.ontextentity(t,this.sectionStart))}}const{fromCodePoint:kr}=String,Fe=new Set(["input","option","optgroup","select","button","datalist","textarea"]),O=new Set(["p"]),Ze=new Set(["h1","h2","h3","h4","h5","h6","p"]),Ir=new Set(["thead","tbody"]),xr=new Set(["dd","dt"]),Sr=new Set(["rt","rp"]),Cd=new Map([["tr",new Set(["tr","th","td"])],["th",new Set(["th"])],["td",new Set(["thead","th","td"])],["body",new Set(["head","link","script"])],["a",new Set(["a"])],["li",new Set(["li"])],["p",O],["h1",Ze],["h2",Ze],["h3",Ze],["h4",Ze],["h5",Ze],["h6",Ze],["select",Fe],["input",Fe],["output",Fe],["button",Fe],["datalist",Fe],["textarea",Fe],["option",new Set(["option"])],["optgroup",new Set(["optgroup","option"])],["dd",xr],["dt",xr],["address",O],["article",O],["aside",O],["blockquote",O],["details",O],["div",O],["dl",O],["fieldset",O],["figcaption",O],["figure",O],["footer",O],["form",O],["header",O],["hr",O],["main",O],["nav",O],["ol",O],["pre",O],["section",O],["table",O],["ul",O],["rt",Sr],["rp",Sr],["tbody",Ir],["tfoot",Ir]]),Cr="doctype",Ed=new Set(["area","base","basefont","br","col","command","embed","frame","hr","img","input","isindex","keygen","link","meta","param","source","track","wbr"]),Bd=new Set(["math","svg"]),Er=new Set(["mi","mo","mn","ms","mtext","annotation-xml","foreignObject","desc","title"]),Br=new Map([["altglyph","altGlyph"],["altglyphdef","altGlyphDef"],["altglyphitem","altGlyphItem"],["animatecolor","animateColor"],["animatemotion","animateMotion"],["animatetransform","animateTransform"],["clippath","clipPath"],["feblend","feBlend"],["fecolormatrix","feColorMatrix"],["fecomponenttransfer","feComponentTransfer"],["fecomposite","feComposite"],["feconvolvematrix","feConvolveMatrix"],["fediffuselighting","feDiffuseLighting"],["fedisplacementmap","feDisplacementMap"],["fedistantlight","feDistantLight"],["fedropshadow","feDropShadow"],["feflood","feFlood"],["fefunca","feFuncA"],["fefuncb","feFuncB"],["fefuncg","feFuncG"],["fefuncr","feFuncR"],["fegaussianblur","feGaussianBlur"],["feimage","feImage"],["femerge","feMerge"],["femergenode","feMergeNode"],["femorphology","feMorphology"],["feoffset","feOffset"],["fepointlight","fePointLight"],["fespecularlighting","feSpecularLighting"],["fespotlight","feSpotLight"],["fetile","feTile"],["feturbulence","feTurbulence"],["foreignobject","foreignObject"],["glyphref","glyphRef"],["lineargradient","linearGradient"],["radialgradient","radialGradient"],["textpath","textPath"]]);var se;(function(e){e[e.None=0]="None",e[e.Svg=1]="Svg",e[e.MathML=2]="MathML"})(se||(se={}));const _d=/\s|\//;class Dd{options;startIndex=0;endIndex=0;openTagStart=0;tagname="";attribname="";attribvalue="";attribs=null;stack=[];foreignContext;cbs;lowerCaseTagNames;lowerCaseAttributeNames;recognizeSelfClosing;htmlMode;tokenizer;buffers=[];bufferOffset=0;writeIndex=0;ended=!1;constructor(t,n={}){this.options=n,this.cbs=t??{},this.htmlMode=!this.options.xmlMode,this.lowerCaseTagNames=n.lowerCaseTags??this.htmlMode,this.lowerCaseAttributeNames=n.lowerCaseAttributeNames??this.htmlMode,this.recognizeSelfClosing=n.recognizeSelfClosing??!this.htmlMode,this.tokenizer=new(n.Tokenizer??Sd)(this.options,this),this.foreignContext=[se.None],this.cbs.onparserinit?.(this)}ontext(t,n){const i=this.getSlice(t,n);this.endIndex=n-1,this.cbs.ontext?.(i),this.startIndex=n}ontextentity(t,n){this.endIndex=n-1,this.cbs.ontext?.(kr(t)),this.startIndex=n}isInForeignContext(){return this.foreignContext[0]!==se.None}isVoidElement(t){return this.htmlMode&&Ed.has(t)}readTagName(t,n){const i=this.lowerCaseTagNames?this.getSlice(t,n).toLowerCase():this.getSlice(t,n);if(!(this.lowerCaseTagNames&&this.htmlMode))return i;if(this.foreignContext[0]===se.Svg)return Br.get(i)??i;if(this.foreignContext.length>1){const r=Br.get(i);if(r!==void 0&&this.stack.includes(r))return r}return this.isInForeignContext()?i:i==="image"?"img":i}onopentagname(t,n){this.endIndex=n,this.emitOpenTag(this.readTagName(t,n))}emitOpenTag(t){if(this.openTagStart=this.startIndex,this.tagname=t,this.htmlMode&&t==="form"&&this.stack.includes("form")){this.tagname="";return}const n=this.htmlMode&&Cd.get(t);if(n)for(;this.stack.length>0&&n.has(this.stack[0]);)this.popElement(!0);this.isVoidElement(t)||(this.stack.unshift(t),this.htmlMode&&(t==="svg"?this.foreignContext.unshift(se.Svg):t==="math"?this.foreignContext.unshift(se.MathML):Er.has(t)&&this.foreignContext.unshift(se.None))),this.cbs.onopentagname?.(t),this.cbs.onopentag&&(this.attribs={})}endOpenTag(t){this.startIndex=this.openTagStart,this.attribs&&(this.cbs.onopentag?.(this.tagname,this.attribs,t),this.attribs=null),this.cbs.onclosetag&&this.isVoidElement(this.tagname)&&this.cbs.onclosetag(this.tagname,!0),this.tagname=""}onopentagend(t){this.endIndex=t,this.endOpenTag(!1),this.startIndex=t+1}onclosetag(t,n){this.endIndex=n;const i=this.readTagName(t,n);if(this.isVoidElement(i))this.htmlMode&&i==="br"&&(this.cbs.onopentagname?.("br"),this.cbs.onopentag?.("br",{},!0),this.cbs.onclosetag?.("br",!1));else{const r=this.stack.indexOf(i);if(r!==-1){for(let s=0;s<r;s++)this.popElement(!0);this.popElement(!1)}else this.htmlMode&&i==="p"&&(this.emitOpenTag("p"),this.closeCurrentTag(!0))}this.startIndex=n+1}onselfclosingtag(t){this.endIndex=t,this.recognizeSelfClosing||this.isInForeignContext()?(this.closeCurrentTag(!1),this.startIndex=t+1):this.onopentagend(t)}popElement(t){const n=this.stack.shift();this.htmlMode&&(Bd.has(n)||Er.has(n))&&this.foreignContext.shift(),this.cbs.onclosetag?.(n,t)}closeCurrentTag(t){const n=this.tagname;this.endOpenTag(t),this.stack[0]===n&&this.popElement(!t)}onattribname(t,n){this.startIndex=t;const i=this.getSlice(t,n);this.attribname=this.lowerCaseAttributeNames?i.toLowerCase():i}onattribdata(t,n){this.attribvalue+=this.getSlice(t,n)}onattribentity(t){this.attribvalue+=kr(t)}onattribend(t,n){this.endIndex=n,this.cbs.onattribute?.(this.attribname,this.attribvalue,t===$.Double?'"':t===$.Single?"'":t===$.NoValue?void 0:null),this.attribs&&!Object.hasOwn(this.attribs,this.attribname)&&(this.attribs[this.attribname]=this.attribvalue),this.attribvalue=""}getInstructionName(t){const n=t.search(_d);let i=n<0?t:t.substr(0,n);return this.lowerCaseTagNames&&(i=i.toLowerCase()),i}ondeclaration(t,n){this.endIndex=n;const i=this.getSlice(t,n);if(this.cbs.onprocessinginstruction){const r=this.htmlMode?this.lowerCaseTagNames?Cr:i.slice(0,Cr.length):this.getInstructionName(i);this.cbs.onprocessinginstruction(`!${r}`,`!${i}`)}this.startIndex=n+1}onprocessinginstruction(t,n){this.endIndex=n;const i=this.getSlice(t,n);if(this.cbs.onprocessinginstruction){const r=this.getInstructionName(i);this.cbs.onprocessinginstruction(`?${r}`,`?${i}`)}this.startIndex=n+1}oncomment(t,n,i){this.endIndex=n,this.cbs.oncomment?.(this.getSlice(t,n-i)),this.cbs.oncommentend?.(),this.startIndex=n+1}oncdata(t,n,i){this.endIndex=n;const r=this.getSlice(t,n-i);!this.htmlMode||this.options.recognizeCDATA?(this.cbs.oncdatastart?.(),this.cbs.ontext?.(r),this.cbs.oncdataend?.()):this.isInForeignContext()?this.cbs.ontext?.(r):(this.cbs.oncomment?.(`[CDATA[${r}]]`),this.cbs.oncommentend?.()),this.startIndex=n+1}onend(){if(this.cbs.onclosetag){this.endIndex=this.startIndex;for(let t=0;t<this.stack.length;t++)this.cbs.onclosetag(this.stack[t],!0)}this.cbs.onend?.()}reset(){this.cbs.onreset?.(),this.tokenizer.reset(),this.tagname="",this.attribname="",this.attribvalue="",this.attribs=null,this.stack.length=0,this.startIndex=0,this.endIndex=0,this.cbs.onparserinit?.(this),this.buffers.length=0,this.foreignContext.length=0,this.foreignContext.unshift(se.None),this.bufferOffset=0,this.writeIndex=0,this.ended=!1}parseComplete(t){this.reset(),this.end(t)}getSlice(t,n){if(t===n)return"";for(;t-this.bufferOffset>=this.buffers[0].length;)this.shiftBuffer();let i=this.buffers[0].slice(t-this.bufferOffset,n-this.bufferOffset);for(;n-this.bufferOffset>this.buffers[0].length;)this.shiftBuffer(),i+=this.buffers[0].slice(0,n-this.bufferOffset);return i}shiftBuffer(){this.bufferOffset+=this.buffers[0].length,this.writeIndex--,this.buffers.shift()}write(t){if(this.ended){this.cbs.onerror?.(new Error(".write() after done!"));return}this.buffers.push(t),this.tokenizer.running&&(this.tokenizer.write(t),this.writeIndex++)}end(t){if(this.ended){this.cbs.onerror?.(new Error(".end() after done!"));return}t&&this.write(t),this.ended=!0,this.tokenizer.end()}pause(){this.tokenizer.pause()}resume(){for(this.tokenizer.resume();this.tokenizer.running&&this.writeIndex<this.buffers.length;)this.tokenizer.write(this.buffers[this.writeIndex++]);this.ended&&this.tokenizer.end()}}var _;(function(e){e.Root="root",e.Text="text",e.Directive="directive",e.Comment="comment",e.Script="script",e.Style="style",e.Tag="tag",e.CDATA="cdata",e.Doctype="doctype"})(_||(_={}));function Nd(e){return e.type===_.Tag||e.type===_.Script||e.type===_.Style}_.Root;const en=_.Text;_.Directive,_.Comment;const Fd=_.Script,Zd=_.Style,Rd=_.Tag;_.CDATA,_.Doctype;class _r{parent=null;prev=null;next=null;startIndex=null;endIndex=null;get parentNode(){return this.parent}set parentNode(t){this.parent=t}get previousSibling(){return this.prev}set previousSibling(t){this.prev=t}get nextSibling(){return this.next}set nextSibling(t){this.next=t}cloneNode(t=!1){return Rr(this,t)}}class tn extends _r{data;constructor(t){super(),this.data=t}get nodeValue(){return this.data}set nodeValue(t){this.data=t}}class nn extends tn{type=_.Text;get nodeType(){return 3}}class Dr extends tn{type=_.Comment;get nodeType(){return 8}}class Nr extends tn{type=_.Directive;name;constructor(t,n){super(n),this.name=t}get nodeType(){return 1}"x-name";"x-publicId";"x-systemId"}class rn extends _r{children;constructor(t){super(),this.children=t}get firstChild(){return this.children[0]??null}get lastChild(){return this.children.length>0?this.children[this.children.length-1]:null}get childNodes(){return this.children}set childNodes(t){this.children=t}}class Fr extends rn{type=_.CDATA;get nodeType(){return 4}}class on extends rn{type=_.Root;get nodeType(){return 9}}class Zr extends rn{name;attribs;type;constructor(t,n,i=[],r=t==="script"?_.Script:t==="style"?_.Style:_.Tag){super(i),this.name=t,this.attribs=n,this.type=r}get nodeType(){return 1}get tagName(){return this.name}set tagName(t){this.name=t}get attributes(){return Object.keys(this.attribs).map(t=>({name:t,value:this.attribs[t],namespace:this["x-attribsNamespace"]?.[t],prefix:this["x-attribsPrefix"]?.[t]}))}namespace;"x-attribsNamespace";"x-attribsPrefix"}function Qd(e){return Nd(e)}function Od(e){return e.type===_.CDATA}function Ud(e){return e.type===_.Text}function Wd(e){return e.type===_.Comment}function zd(e){return e.type===_.Directive}function Kd(e){return e.type===_.Root}function Rr(e,t=!1){let n;if(Ud(e))n=new nn(e.data);else if(Wd(e))n=new Dr(e.data);else if(Qd(e)){const i=t?an(e.children):[],r=new Zr(e.name,{...e.attribs},i);for(const s of i)s.parent=r;e.namespace!=null&&(r.namespace=e.namespace),e["x-attribsNamespace"]&&(r["x-attribsNamespace"]={...e["x-attribsNamespace"]}),e["x-attribsPrefix"]&&(r["x-attribsPrefix"]={...e["x-attribsPrefix"]}),n=r}else if(Od(e)){const i=t?an(e.children):[],r=new Fr(i);for(const s of i)s.parent=r;n=r}else if(Kd(e)){const i=t?an(e.children):[],r=new on(i);for(const s of i)s.parent=r;e["x-mode"]&&(r["x-mode"]=e["x-mode"]),n=r}else if(zd(e)){const i=new Nr(e.name,e.data);e["x-name"]!=null&&(i["x-name"]=e["x-name"],i["x-publicId"]=e["x-publicId"],i["x-systemId"]=e["x-systemId"]),n=i}else throw new Error(`Not implemented yet: ${e.type}`);return n.startIndex=e.startIndex,n.endIndex=e.endIndex,e.sourceCodeLocation!=null&&(n.sourceCodeLocation=e.sourceCodeLocation),n}function an(e){const t=e.map(n=>Rr(n,!0));for(let n=1;n<t.length;n++)t[n].prev=t[n-1],t[n-1].next=t[n];return t}const Qr={withStartIndices:!1,withEndIndices:!1,xmlMode:!1};class Td{dom=[];root=new on(this.dom);callback;options;elementCB;done=!1;tagStack=[this.root];lastNode=null;parser=null;constructor(t,n,i){typeof n=="function"&&(i=n,n=Qr),typeof t=="object"&&(n=t,t=void 0),this.callback=t??null,this.options=n??Qr,this.elementCB=i??null}onparserinit(t){this.parser=t}onreset(){this.dom=[],this.root=new on(this.dom),this.done=!1,this.tagStack=[this.root],this.lastNode=null,this.parser=null}onend(){this.done||(this.done=!0,this.parser=null,this.handleCallback(null))}onerror(t){this.handleCallback(t)}onclosetag(){this.lastNode=null;const t=this.tagStack.pop();this.options.withEndIndices&&this.parser&&(t.endIndex=this.parser.endIndex),this.elementCB&&this.elementCB(t)}onopentag(t,n){const i=this.options.xmlMode?_.Tag:void 0,r=new Zr(t,n,void 0,i);this.addNode(r),this.tagStack.push(r)}ontext(t){const{lastNode:n}=this;if(n&&n.type===_.Text)n.data+=t,this.options.withEndIndices&&this.parser&&(n.endIndex=this.parser.endIndex);else{const i=new nn(t);this.addNode(i),this.lastNode=i}}oncomment(t){if(this.lastNode&&this.lastNode.type===_.Comment){this.lastNode.data+=t;return}const n=new Dr(t);this.addNode(n),this.lastNode=n}oncommentend(){this.lastNode=null}oncdatastart(){const t=new nn(""),n=new Fr([t]);this.addNode(n),t.parent=n,this.lastNode=t}oncdataend(){this.lastNode=null}onprocessinginstruction(t,n){const i=new Nr(t,n);this.addNode(i)}handleCallback(t){if(typeof this.callback=="function")this.callback(t,this.dom);else if(t)throw t}addNode(t){const n=this.tagStack[this.tagStack.length-1],i=n.children[n.children.length-1];this.options.withStartIndices&&this.parser&&(t.startIndex=this.parser.startIndex),this.options.withEndIndices&&this.parser&&(t.endIndex=this.parser.endIndex),n.children.push(t),i&&(t.prev=i,i.next=t),t.parent=n,this.lastNode=null}}function Gd(e,t){const n=new Td(void 0,t);return new Dd(n,t).end(e),n.root}const sn=new Set(["script","style","template"]),Or=new Set([Rd,Fd,Zd]),Md=new Set(["p","pre","blockquote","li","dt","dd","tr","figure","img","svg","canvas","picture","fieldset","label"]),Jd=new Set(["group","radiogroup"]),Ur=["data-facts","data-followups"],Wr=`${ae}://${Hi}/`,zr=`${ae}://${qi}/`;function Yd(e,t){if(Md.has(t))return!0;const n=e.attribs?.role?.trim().toLowerCase();return n!==void 0&&Jd.has(n)}function Ld(e,t){return e==="src"&&t.startsWith(Wr)&&ji(t.slice(Wr.length))?"picture":Kl("demo").includes(e)&&t.startsWith(zr)&&Vi(t.slice(zr.length))?"recording":t.replace(/\s+/g," ").trim()}function cn(e,t,n=!1){if(e.type===en)return(e.data??"").replace(/\s+/g," ").trim();if(!Or.has(e.type))return"";const i=e.name?.toLowerCase()??"";if(Ur.some(c=>e.attribs?.[c]!==void 0)||!n&&sn.has(i))return"";const r=Object.entries(e.attribs??{}).map(([c,l])=>[c.toLowerCase(),Ld(c.toLowerCase(),l)]).sort(([c],[l])=>c<l?-1:c>l?1:0).map(([c,l])=>`${c}="${l}"`).join(" "),s=(e.children??[]).map(c=>cn(c,t,n)).filter(Boolean);n&&!(e.children??[]).some(c=>c.type===en&&(c.data??"").trim())&&s.sort();const o=s.join(" ");return`<${i}${r?` ${r}`:""}>${o}</${i}>`}function Pd(e,t){const n=Gd(e,{decodeEntities:!0,withStartIndices:!0}),i=[],r=[],s=c=>c.type===en?c.data??"":sn.has(c.name??"")?"":(c.children??[]).map(l=>s(l)).join(" "),o=(c,l)=>{for(const A of c){if(!Or.has(A.type))continue;const m=A.name?.toLowerCase()??"";if(sn.has(m)||Ur.some(v=>A.attribs?.[v]!==void 0))continue;const y=A.startIndex,I=/^h[1-6]$/.test(m)?Number(m[1]):0;if(I&&typeof y=="number"){const v=s(A).replace(/\s+/g," ").trim();for(;r.length&&r[r.length-1].level>=I;)r.pop();const B={start:y,label:v,path:JSON.stringify([...r.map(be=>be.area.label),v]),...A.attribs?.id||l?{stableId:A.attribs?.id||l}:{}};r.push({level:I,area:B}),i.push({start:y,key:cn(A,t),heading:!0,area:B})}else Yd(A,m)&&typeof y=="number"?i.push({start:y,key:cn(A,t),heading:!1,...r.at(-1)?{area:r.at(-1).area}:{}}):o(A.children??[],A.attribs?.id||l)}};return o(n.children),i}const Hd=`/* Shared by the shell and frame documents; no geometry or close choreography. */
[data-in-place-reveal="drift"] {
  animation: in-place-reveal var(--dur-fast) var(--ease-out);
}
[data-in-place-reveal="fade"] {
  animation: in-place-fade var(--dur-fast) var(--ease-out);
}
@keyframes in-place-reveal {
  from {
    opacity: 0;
    transform: translateY(calc(-1 * var(--space-1)));
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
@keyframes in-place-fade {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
/* Native details owns the hidden body, including bare text. No wrappers or
   author-script changes. Initial open markup has no previous style and is
   static; only a closed-to-open change transitions. Close removes transition.
   Content visibility never transitions: an opening one starts from hidden
   until the animation's first frame, and its controls cannot take focus. */
details::details-content {
  opacity: 0;
  transform: translateY(calc(-1 * var(--space-1)));
}
details[open]::details-content {
  opacity: 1;
  transform: translateY(0);
  transition:
    opacity var(--dur-fast) var(--ease-out),
    transform var(--dur-fast) var(--ease-out);
}
`,qd=`/* Infinitary — color system. Dark ("deep space") is the default theme; light opts in via [data-theme="light"]. */
:root {
  /* base */
  --bg-0: #05070d; /* void — the opaque fallback behind --material-tint */
  --material-tint: rgba(5, 7, 13, 1); /* opaque tint mixed toward clear by wash percentage */
  --bg-1: #0a0e18; /* surface — panels, input shell */
  --bg-2: #0f1424; /* raised — cards */
  --bg-3: #161c30; /* overlay hover */
  --line-1: rgba(150, 180, 255, 0.2); /* hairline borders, set for the material */
  --line-2: rgba(150, 180, 255, 0.24); /* focused / active borders */
  --fg-1: #e9eef8; /* primary text */
  --fg-2: #98a4bd; /* secondary text */
  --fg-3: #7a86a0; /* tertiary / placeholder, lifted for the material */
  /* accent — ice cyan, the Firstmate's light */
  --accent: #7fdcff;
  --accent-strong: #38aae6;
  --accent-dim: rgba(127, 220, 255, 0.14);
  --accent-glow: rgba(127, 220, 255, 0.35);
  /* semantic — two chromatic families only: ice cyan (calm) and ember (hot) */
  --ok: #7fdcff; /* calm cyan — done, pace ahead (same family as accent) */
  --ok-dim: rgba(127, 220, 255, 0.14);
  --hot: #ffa257; /* ember — the one hot color: energy, sun, fire */
  --hot-dim: rgba(255, 162, 87, 0.14);
  --hot-glow: rgba(255, 148, 66, 0.35);
  --warn: #ffa257; /* attention, pace behind — ember */
  --warn-dim: rgba(255, 162, 87, 0.14);
  --danger: #ff6b52; /* lava — errors, exhausted quota (hot family, redder) */
  --danger-dim: rgba(255, 107, 82, 0.12);
  --captain: #b99aff; /* violet — the captain's own activity */
  --captain-dim: rgba(185, 154, 255, 0.14);
  --idle: #5d6884; /* dormant crewmates, inactive */
  /* intelligence slots - celestial: supernova (lava) / sun / earth / moon.
     supernova sits above the sun and is the one slot the app never reaches
     for on its own. --bucket-* aliases keep older mocks working. */
  --slot-premium: #ff6b52;
  --slot-high: #ffa257;
  --slot-medium: #7fdcff;
  --slot-low: #8a93a8;
  --bucket-premium: var(--slot-premium);
  --bucket-high: var(--slot-high);
  --bucket-medium: var(--slot-medium);
  --bucket-low: var(--slot-low);
  /* wireframe characters (canvas) */
  --wire-accent: #7fdcff;
  --wire-hot: #ffa257;
  --wire-dim: #2e6a8c; /* far side — same cyan family, darker */
  --wire-boost: 1; /* @kind other */ /* alpha multiplier — raised in light theme where thin lines wash out */
  --halo-boost: 1.2; /* @kind other */ /* the Firstmate's halo, lifted so it reads over the material */
  color-scheme: dark;
}
[data-theme="light"] {
  --bg-0: #eef1f7;
  --material-tint: rgba(238, 241, 247, 1);
  --bg-1: #f7f9fc;
  --bg-2: #ffffff;
  --bg-3: #e7ecf5;
  --line-1: rgba(30, 50, 90, 0.18);
  --line-2: rgba(30, 50, 90, 0.26);
  --fg-1: #151b2b;
  --fg-2: #4d5a75;
  --fg-3: #6c7891;
  --accent: #0e8fd0;
  --accent-strong: #0a72a8;
  --accent-dim: rgba(14, 143, 208, 0.1);
  --accent-glow: rgba(14, 143, 208, 0.25);
  --ok: #0e8fd0;
  --ok-dim: rgba(14, 143, 208, 0.1);
  --hot: #d97a1f;
  --hot-dim: rgba(217, 122, 31, 0.12);
  --hot-glow: rgba(217, 122, 31, 0.28);
  --warn: #d97a1f;
  --warn-dim: rgba(217, 122, 31, 0.12);
  --danger: #cf4a2e;
  --danger-dim: rgba(207, 74, 46, 0.1);
  --captain: #7254c9;
  --captain-dim: rgba(114, 84, 201, 0.12);
  --idle: #8b96ad;
  --slot-premium: #cf4a2e;
  --slot-high: #d97a1f;
  --slot-medium: #0e8fd0;
  --slot-low: #8b96ad;
  --bucket-premium: var(--slot-premium);
  --bucket-high: var(--slot-high);
  --bucket-medium: var(--slot-medium);
  --bucket-low: var(--slot-low);
  --wire-accent: #0a72a8;
  --wire-hot: #e8760a;
  --wire-dim: #82b4cf; /* far side — same cyan family, lighter/desaturated */
  --wire-boost: 1.4; /* @kind other */
  --halo-boost: 1.2; /* @kind other */
  color-scheme: light;
}
/* Semantic aliases — declared on BOTH theme scopes so var() re-resolves inside [data-theme="light"] (aliases declared only on :root would freeze to dark values). */
:root,
[data-theme="light"] {
  --surface-card: var(--bg-2);
  --surface-input: var(--bg-1);
  --text-body: var(--fg-1);
  --text-muted: var(--fg-2);
  --text-faint: var(--fg-3);
  --focus-ring: 0 0 0 1px var(--line-2), 0 0 24px -6px var(--accent-glow);
  /* The same ring, drawn inside an edge that cuts it. */
  --focus-ring-inset: inset 0 0 0 1px var(--line-2), inset 0 0 24px -6px var(--accent-glow);
}
`,jd=`/* Infinitary — radii, shadows, glow, blur, motion. */
:root {
  --radius-xs: 3px; /* small controls: a 14-16px box that must read square, not round */
  --radius-s: 6px; /* badges, keycaps */
  --radius-m: 10px; /* buttons, inputs */
  --radius-l: 16px; /* cards, panels */
  --radius-pill: 999px; /* voice input shell, pills */
  --shadow-1: 0 1px 2px rgba(0, 0, 0, 0.35);
  --shadow-2: 0 8px 30px -12px rgba(0, 0, 0, 0.6);
  --shadow-card: 0 12px 40px -16px rgba(0, 0, 0, 0.65), 0 1px 0 rgba(150, 180, 255, 0.06) inset;
  --glow-accent: 0 0 32px -8px var(--accent-glow);
  /* solid card material (legacy acrylic token names) */
  --acrylic-bg: var(--bg-2);
  --acrylic-blur: none; /* @kind other */
  --acrylic-border: var(--line-1);
  --acrylic-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.1), 0 24px 48px -24px rgba(0, 0, 0, 0.6);
  --blur-overlay: blur(16px); /* @kind other */
  /* motion — 160 in place, 360 for a surface, 700 for a dissolve; the card
     stack, popovers, summaries and button labels have their own moves below */
  --ease-drift: cubic-bezier(0.25, 0.1, 0.25, 1); /* @kind other */
  --ease-out: cubic-bezier(0.32, 0.72, 0, 1); /* @kind other — the glide */
  --dur-fast: 160ms; /* @kind other */
  --dur-med: 360ms; /* @kind other */
  --dur-slow: 700ms; /* @kind other */
  --dur-fade: 160ms; /* @kind other — opacity-only opt-in, also under reduced motion */
  --dur-quick: 200ms; /* @kind other — a popover grows, a summary slides or moves, a closed card drops away */
  --dur-page: 300ms; /* @kind other — a card pages in, or comes forward after a close */
  --dur-arrive: 420ms; /* @kind other — a card arrives on an empty stage */
  --dur-popover-out: 120ms; /* @kind other */
  --dur-summary-out: 100ms; /* @kind other */
  --delay-label: 500ms; /* @kind other — the first icon-button label waits this long */
  --move-page: 32px; /* @kind other — paging slides this far, with the arrow */
  --move-arrive: 12px; /* @kind other */
  --move-drop: 10px; /* @kind other — a closed card drops this far */
  --move-stack: 8px; /* @kind other — the next card comes forward from this far up */
  --move-summary: 8px; /* @kind other — a summary slides this far from what it describes */
  --scale-arrive: 0.98; /* @kind other */
  --scale-stack: 0.97; /* @kind other — a card behind the shown one */
  --scale-pop: 0.94; /* @kind other — a popover grows from this size */
}
[data-theme="light"] {
  --shadow-1: 0 1px 2px rgba(20, 30, 60, 0.1);
  --shadow-2: 0 8px 30px -12px rgba(20, 30, 60, 0.18);
  --shadow-card: 0 12px 40px -16px rgba(20, 30, 60, 0.22);
  --acrylic-bg: var(--bg-2);
  --acrylic-blur: none; /* @kind other */
  --acrylic-border: var(--line-1);
  --acrylic-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.9), 0 12px 32px -12px rgba(20, 30, 60, 0.28),
    0 2px 8px -2px rgba(20, 30, 60, 0.1);
}

/* Shared by the shell and every frame. Character motion has its own guard.
   Only short, explicitly opted-in opacity fades survive. */
@media (prefers-reduced-motion: reduce) {
  :root {
    --dur-fast: 0ms;
    --dur-med: 0ms;
    --dur-slow: 0ms;
    --dur-quick: 0ms;
    --dur-page: 0ms;
    --dur-arrive: 0ms;
    --dur-popover-out: 0ms;
    --dur-summary-out: 0ms;
  }
}
`,Vd=`/* Infinitary webfonts - Space Grotesk (UI/display) + JetBrains Mono (data/code).
   Vendored locally from Google Fonts (SIL Open Font License 1.1) so the package is offline-complete.
   Binaries live in assets/fonts/; regenerate by re-fetching the css2 URL below with a woff2-capable UA.
   https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300..700&family=JetBrains+Mono:ital,wght@0,300..700;1,300..700&display=swap */
/* JetBrains Mono italic cyrillic-ext */
@font-face {
  font-family: "JetBrains Mono";
  font-style: italic;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-italic-cyrillic-ext.woff2) format("woff2");
  unicode-range: U+0460-052F, U+1C80-1C8A, U+20B4, U+2DE0-2DFF, U+A640-A69F, U+FE2E-FE2F;
}
/* JetBrains Mono italic cyrillic */
@font-face {
  font-family: "JetBrains Mono";
  font-style: italic;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-italic-cyrillic.woff2) format("woff2");
  unicode-range: U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116;
}
/* JetBrains Mono italic greek */
@font-face {
  font-family: "JetBrains Mono";
  font-style: italic;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-italic-greek.woff2) format("woff2");
  unicode-range: U+0370-0377, U+037A-037F, U+0384-038A, U+038C, U+038E-03A1, U+03A3-03FF;
}
/* JetBrains Mono italic vietnamese */
@font-face {
  font-family: "JetBrains Mono";
  font-style: italic;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-italic-vietnamese.woff2) format("woff2");
  unicode-range:
    U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;
}
/* JetBrains Mono italic latin-ext */
@font-face {
  font-family: "JetBrains Mono";
  font-style: italic;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-italic-latin-ext.woff2) format("woff2");
  unicode-range:
    U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;
}
/* JetBrains Mono italic latin */
@font-face {
  font-family: "JetBrains Mono";
  font-style: italic;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-italic-latin.woff2) format("woff2");
  unicode-range:
    U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
}
/* JetBrains Mono normal cyrillic-ext */
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-normal-cyrillic-ext.woff2) format("woff2");
  unicode-range: U+0460-052F, U+1C80-1C8A, U+20B4, U+2DE0-2DFF, U+A640-A69F, U+FE2E-FE2F;
}
/* JetBrains Mono normal cyrillic */
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-normal-cyrillic.woff2) format("woff2");
  unicode-range: U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116;
}
/* JetBrains Mono normal greek */
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-normal-greek.woff2) format("woff2");
  unicode-range: U+0370-0377, U+037A-037F, U+0384-038A, U+038C, U+038E-03A1, U+03A3-03FF;
}
/* JetBrains Mono normal vietnamese */
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-normal-vietnamese.woff2) format("woff2");
  unicode-range:
    U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;
}
/* JetBrains Mono normal latin-ext */
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-normal-latin-ext.woff2) format("woff2");
  unicode-range:
    U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;
}
/* JetBrains Mono normal latin */
@font-face {
  font-family: "JetBrains Mono";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/jetbrainsmono-normal-latin.woff2) format("woff2");
  unicode-range:
    U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
}
/* Space Grotesk normal vietnamese */
@font-face {
  font-family: "Space Grotesk";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/spacegrotesk-vietnamese.woff2) format("woff2");
  unicode-range:
    U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;
}
/* Space Grotesk normal latin-ext */
@font-face {
  font-family: "Space Grotesk";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/spacegrotesk-latin-ext.woff2) format("woff2");
  unicode-range:
    U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;
}
/* Space Grotesk normal latin */
@font-face {
  font-family: "Space Grotesk";
  font-style: normal;
  font-weight: 300 700;
  font-display: swap;
  src: url(../assets/fonts/spacegrotesk-latin.woff2) format("woff2");
  unicode-range:
    U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;
}
`,Xd=`/* Infinitary — spacing scale (4px base). Generous whitespace is the default; density is the exception. */
:root {
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-5: 24px;
  --space-6: 32px;
  --space-7: 48px;
  --space-8: 64px;
  --space-9: 96px;
  /* layout - dock rails are at least one fifth of the window, not resizable */
  --rail-width: max(300px, 20vw);
  /* layout - the voice input: one line is the pill, and the radius stays half of it at every height */
  --prompt-height: calc(var(--space-7) + var(--space-1));
  --prompt-radius: calc(var(--prompt-height) / 2);
  /* layout - a card's reply field: one line of --text-sm is the pill (2px is its hairline), and the radius stays half of it at every height */
  --reply-height: calc(var(--text-sm) * var(--leading-body) + 2 * var(--space-2) + 2px);
  --reply-radius: calc(var(--reply-height) / 2);
}
`,$d=`/* Infinitary — typography. Space Grotesk for UI and display, JetBrains Mono for data, keybinds, code. */
:root {
  --font-ui: "Space Grotesk", system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;
  --text-xs: 11px; /* micro labels, uppercase tracked */
  --text-sm: 12.5px; /* secondary, metadata */
  --text-base: 14px; /* body */
  --text-md: 16px; /* card titles, input text */
  --text-lg: 20px; /* section titles */
  --text-xl: 28px; /* card headlines */
  --text-display: 44px; /* null-state greeting */
  --leading-tight: 1.15;
  --leading-body: 1.55;
  --tracking-label: 0.09em; /* uppercase micro labels */
  --tracking-display: -0.02em;
  --weight-light: 300;
  --weight-regular: 400;
  --weight-medium: 500;
  --weight-semibold: 600;
}
body {
  font-family: var(--font-ui);
  font-size: var(--text-base);
  line-height: var(--leading-body);
  color: var(--text-body);
  background: var(--bg-0);
  -webkit-font-smoothing: antialiased;
}
a {
  color: var(--accent);
  text-decoration: none;
}
a:hover {
  color: var(--accent-strong);
}
`,eh=/url\(\s*['"]?\.\.\/assets\/fonts\/([A-Za-z0-9._-]+)['"]?\s*\)/g;function th(e=Vd){return e.replaceAll(eh,(t,n)=>`url(${cd(n)})`)}const nh=`
  * { box-sizing: border-box; }
  html, body { margin: 0; padding: 0; }
  body {
    font-family: var(--font-ui);
    font-size: var(--text-base);
    line-height: var(--leading-body);
    color: var(--fg-2);
    background: transparent;
    padding: var(--space-1);
  }
  h1, h2, h3, h4, h5, h6 { color: var(--fg-1); font-weight: 500; letter-spacing: var(--tracking-display); line-height: var(--leading-tight); margin: 0 0 var(--space-2); }
  h1 { font-size: var(--text-lg); }
  h2 { font-size: var(--text-md); }
  h3, h4 { font-size: var(--text-base); }
  h4 { color: var(--fg-2); }
  h5 { font-size: var(--text-sm); }
  h6 { font-size: var(--text-xs); color: var(--fg-3); letter-spacing: var(--tracking-label); text-transform: uppercase; }
  p, ul, ol, pre, blockquote, figure, dl, table, details { margin: 0 0 var(--space-2); }
  figcaption { font-size: var(--text-sm); color: var(--fg-3); margin-top: var(--space-1); }
  mark { color: var(--fg-1); background: var(--accent-dim); border-radius: var(--radius-xs); padding: 0 var(--space-1); }
  kbd {
    font-family: var(--font-mono); font-size: var(--text-sm); color: var(--fg-2);
    background: var(--bg-3); border: 1px solid var(--line-1); border-bottom-width: 2px;
    border-radius: var(--radius-s); padding: 0 var(--space-1);
  }
  details { border: 1px solid var(--line-1); border-radius: var(--radius-m); padding: var(--space-2) var(--space-3); }
  summary {
    display: flex; align-items: center; gap: var(--space-2); list-style: none; cursor: pointer;
    color: var(--fg-1); font-weight: 500;
  }
  summary::-webkit-details-marker { display: none; }
  summary::before {
    content: ""; flex: none; border-left: 5px solid var(--fg-3);
    border-top: 4px solid transparent; border-bottom: 4px solid transparent;
    transition: transform var(--dur-fast) var(--ease-out);
  }
  summary:hover::before { border-left-color: var(--fg-1); }
  details[open] > summary { margin-bottom: var(--space-2); }
  details[open] > summary::before { transform: rotate(90deg); }
  details > :last-child { margin-bottom: 0; }
  svg { max-width: 100%; height: auto; color: var(--fg-2); fill: currentColor; font-family: var(--font-ui); font-size: var(--text-sm); }
  /* Inherited fill closes an open bend into a triangle. Leave intentional
     fills on paths (including arrowheads) and labels/shapes untouched. */
  svg :is(path, polyline, line):not([fill]):not([style*="fill"]) { fill: none; }
  body > svg, figure > svg, details > svg { display: block; }
  body > svg, details > svg { margin: 0 0 var(--space-2); }
  /* A picture never reaches past the body; one that would stand taller than
     360 px shrinks to fit 360 px, whole, letterboxed on --bg-1. A click opens
     it in the picture viewer (the bridge's image message), unless it sits in
     a control, which owns the click. */
  img {
    display: block; max-width: 100%; height: auto;
    max-height: 360px; object-fit: contain; background: var(--bg-1);
    cursor: zoom-in;
  }
  :is(a, button, summary, label, [data-inf-action]) img { cursor: inherit; }
  body > img, details > img { margin: 0 0 var(--space-2); }
  /* A group of pictures (card pictures, phase 2; layout C, lead and strip):
     <figure class="inf-pictures"> around several <img>. The first leads under
     the plain img rule, alone on its line; the rest are 88 x 60 thumbnails
     cropped to their top; five show, and past that a mono "+N" tile counts
     the ones not shown. The author's figcaption is the group's caption. All
     of it is this stylesheet, so a group a body builds from its own data:
     pictures looks the same as one the host verified. */
  .inf-pictures {
    display: flex; flex-wrap: wrap; align-items: flex-start; column-gap: var(--space-2);
    position: relative; margin: 0; counter-reset: inf-pictures-more;
  }
  .inf-pictures > img { flex: none; margin: 0 0 var(--space-2); }
  .inf-pictures > img:first-of-type { order: -2; }
  /* The line break after the lead: an empty line of its own. */
  .inf-pictures::before { content: ""; order: -1; flex: 0 0 100%; height: 0; }
  .inf-pictures > img:nth-of-type(n+2) {
    box-sizing: border-box; width: 88px; height: 60px; max-height: none;
    object-fit: cover; object-position: top;
    border: 1px solid var(--line-1); border-radius: var(--radius-s);
  }
  /* Past the fifth thumbnail a picture is not shown, but still counted and
     still read by a screen reader. */
  .inf-pictures > img:nth-of-type(n+7) {
    position: absolute; width: 1px; height: 1px; margin: 0; border: 0; overflow: hidden;
    clip-path: inset(50%); counter-increment: inf-pictures-more;
  }
  /* The tile takes what is left of the last thumbnail's line, up to a
     thumbnail's width, so it stays beside the fifth instead of wrapping. A
     click on it opens the group at the first picture it counts. */
  .inf-pictures:has(> img:nth-of-type(7))::after {
    content: "+" counter(inf-pictures-more); flex: 1 1 0; box-sizing: border-box;
    min-width: 28px; max-width: 88px; height: 60px; margin: 0 0 var(--space-2);
    display: flex; align-items: center; justify-content: center;
    font-family: var(--font-mono); font-size: var(--text-sm); color: var(--fg-1);
    background: var(--bg-1); border: 1px solid var(--line-1); border-radius: var(--radius-s);
    cursor: zoom-in;
  }
  .inf-pictures > figcaption { order: 1; flex: 0 0 100%; margin: 0 0 var(--space-2); }
  /* A demo (docs/card-authoring.md "Demo recordings"): its poster shows like
     any picture, and the bridge draws one Play button under it, with the
     recording's length, which opens the viewer playing it. Nothing in the
     body moves. */
  [data-inf-demo-play] {
    display: flex; align-items: center; gap: var(--space-2); width: max-content;
    margin: var(--space-2) 0 0; background: var(--bg-2);
  }
  [data-inf-demo-play]::before {
    content: ""; flex: none; width: 0; height: 0;
    border-style: solid; border-width: 5px 0 5px 8px;
    border-color: transparent transparent transparent currentColor;
  }
  /* Something new (card pictures, contract v4.69): a figure marked
     data-inf-new carries a mono New tag over its first corner, so a picture
     with no before reads as new, never as an omission. */
  [data-inf-new] { position: relative; }
  [data-inf-new]::before {
    content: "New"; position: absolute; top: var(--space-1); left: var(--space-1); z-index: 1;
    padding: 1px var(--space-1); pointer-events: none;
    font-family: var(--font-mono); font-size: var(--text-xs); color: var(--fg-1);
    background: var(--accent-dim); border: 1px solid var(--accent); border-radius: var(--radius-s);
  }
  /* One picture per theme (the startup note's hero pairs, docs/release-notes.md):
     an element marked data-inf-theme shows only while the frame is in that
     theme, so a dark and a light picture of one view swap when the theme does. */
  :root:not([data-theme="light"]) [data-inf-theme="light"],
  :root[data-theme="light"] [data-inf-theme="dark"] { display: none; }
  ul, ol { padding-left: var(--space-4); }
  li + li { margin-top: var(--space-1); }
  a { color: var(--accent); text-decoration: underline; text-underline-offset: 2px; }
  /* A task key the bridge linked (FI3-594) reads as a link in the words around it;
     resting on it marks it with a row's hover surface while its summary is open,
     and so does a rest on the same task elsewhere in the window (data-inf-lit, INF-237). */
  a[data-inf-task] { cursor: pointer; border-radius: var(--radius-s); }
  a[data-inf-task]:hover, a[data-inf-task][data-inf-lit] { background: var(--bg-3); }
  /* A knowledge reference the bridge linked (docs/knowledge.md, "References in an
     answer"): the entry's id as a link, led by a dot in its standing's state color -
     ok for checked with evidence, warn for one to recheck or with differing evidence. */
  a[data-inf-entry] { cursor: pointer; border-radius: var(--radius-s); font-family: var(--font-mono); white-space: nowrap; }
  a[data-inf-entry]:hover { background: var(--bg-3); }
  a[data-inf-entry]::before {
    content: ""; display: inline-block; width: 6px; height: 6px; margin: 0 4px 1px 1px;
    border-radius: 50%; background: var(--fg-3); vertical-align: middle;
  }
  a[data-inf-entry][data-inf-standing="ok"]::before { background: var(--ok); }
  a[data-inf-entry][data-inf-standing="warn"]::before { background: var(--warn); }
  code, pre, .inf-mono { font-family: var(--font-mono); font-size: var(--text-sm); color: var(--fg-1); }
  /* A link in mono - a pull request a body names by its number (FI3-1307) - reads as
     every pull request link the app draws: the accent, underlined only while rested on. */
  a.inf-mono { color: var(--accent); text-decoration: none; }
  a.inf-mono:hover { text-decoration: underline; }
  .inf-muted { color: var(--fg-3); }
  .inf-row { display: flex; align-items: center; gap: var(--space-2); }
  .inf-grid { display: grid; gap: var(--space-2); }
  .inf-panel { padding: var(--space-3); border: 1px solid var(--line-1); border-radius: var(--radius-m); }
  .inf-facts { display: flex; flex-wrap: wrap; gap: var(--space-2) var(--space-4); }
  /* Its hairline parts it from a body above; beside a card's buttons it stands alone. */
  * + .inf-facts { border-top: 1px solid var(--line-1); padding-top: var(--space-2); margin: var(--space-3) 0 0; }
  .inf-fact { display: flex; flex-direction: column; min-width: 0; max-width: 100%; }
  .inf-fact-k { font-size: var(--text-xs); color: var(--fg-3); letter-spacing: var(--tracking-label); text-transform: uppercase; white-space: nowrap; }
  .inf-fact-v { font-size: var(--text-sm); color: var(--fg-2); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  /* A pull request reads as every pull request link the app draws: underlined only while rested on. */
  .inf-fact-v a { text-decoration: none; }
  .inf-fact-v a:hover { text-decoration: underline; }
  .inf-facts > .inf-check-verdict { flex-basis: 100%; min-width: 0; margin: 0; padding: 0; border: 0; font-size: var(--text-sm); }
  .inf-check-verdict summary { overflow-wrap: anywhere; }
  .inf-check-verdict summary > span:last-child { color: var(--fg-2); }
  .inf-check-evidence { white-space: pre-wrap; overflow-wrap: anywhere; color: var(--fg-3); }
  /* The host's own line under a failed check: main fails it too, in the open. */
  .inf-facts > .inf-check-outside { flex-basis: 100%; min-width: 0; margin: calc(-1 * var(--space-1)) 0 0; font-size: var(--text-sm); color: var(--fg-2); overflow-wrap: anywhere; }
  /* The app's line on a merge card: whether its click closes the task (INF-2490). */
  .inf-facts > .inf-merge-closes { flex-basis: 100%; min-width: 0; margin: 0; font-size: var(--text-sm); color: var(--fg-1); }
  .inf-followups { margin: var(--space-3) 0 0; }
  .inf-followups-k { font-size: var(--text-xs); color: var(--fg-3); letter-spacing: var(--tracking-label); text-transform: uppercase; margin-bottom: 2px; }
  .inf-followup { display: grid; grid-template-columns: auto minmax(0, 1fr) auto; align-items: baseline; column-gap: var(--space-2); font-size: var(--text-sm); line-height: 1.8; }
  .inf-followup-key { font-family: var(--font-mono); font-size: var(--text-xs); color: var(--fg-3); }
  .inf-followup-title { color: var(--fg-2); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .inf-followup-word { color: var(--fg-3); white-space: nowrap; }
  .inf-followup[data-followup="hold"] .inf-followup-word { color: var(--warn); }
  .inf-fact-dot { vertical-align: -1px; margin-right: var(--space-1); }
  /* The rounds a cap counts, after a cell's words (factRoundsSvg), and the word held once the cap stands. */
  .inf-fact-rounds { vertical-align: -1px; margin-left: var(--space-2); }
  .inf-fact-held { color: var(--danger); margin-left: var(--space-1); }
  /* What a card's button sends where the project lives, drawn by the host (FI3-1571). */
  .inf-call { margin: var(--space-3) 0 0; padding: var(--space-2) var(--space-3); border: 1px solid var(--line-1); border-radius: var(--radius-m); }
  .inf-call-k { font-size: var(--text-xs); color: var(--fg-3); letter-spacing: var(--tracking-label); text-transform: uppercase; margin-bottom: 2px; }
  .inf-call-line { font-family: var(--font-mono); font-size: var(--text-sm); color: var(--fg-1); overflow-wrap: anywhere; }
  .inf-call pre { margin: var(--space-1) 0 0; padding: var(--space-2); background: var(--bg-1); border-radius: var(--radius-s); max-height: 240px; overflow: auto; white-space: pre-wrap; overflow-wrap: anywhere; }
  .inf-call ul { margin: var(--space-1) 0 0; }
  .inf-call li[data-inf-skip="check"] { color: var(--warn); }
  .inf-call-gap details { border: 0; padding: 0; margin: var(--space-2) 0 0; }
  .inf-call-gap fieldset label + details { margin: var(--space-1) 0 var(--space-2) var(--space-5); }
  .inf-call-gap dt { font-size: var(--text-xs); color: var(--fg-3); letter-spacing: var(--tracking-label); text-transform: uppercase; margin-top: var(--space-2); }
  .inf-call-gap dd { margin: var(--space-1) 0 0; color: var(--fg-2); }
  .inf-call-gap dd.inf-mono { color: var(--fg-1); }
  .inf-call p { margin: var(--space-1) 0 0; font-size: var(--text-sm); }
  table { width: 100%; border-collapse: collapse; }
  th, td { padding: var(--space-2); border-bottom: 1px solid var(--line-1); text-align: left; }
  th { color: var(--fg-1); font-weight: 500; }
  input, select, textarea {
    font-family: var(--font-ui); font-size: var(--text-base); color: var(--fg-1);
    background: var(--surface-input); border: 1px solid var(--line-1);
    border-radius: var(--radius-m); padding: var(--space-2) var(--space-3); outline: none;
  }
  input:focus, select:focus, textarea:focus { border-color: var(--line-2); box-shadow: var(--focus-ring); }
  /* Questions in the body (inline decisions, contract 4.22): a fieldset is
     one question, its legend the ask and each option a row of its own. The
     author may present a question however it reads best; these rules only
     keep a plain form on-brand. */
  fieldset {
    min-width: 0; margin: 0 0 var(--space-2); padding: var(--space-1) var(--space-3) var(--space-3);
    border: 1px solid var(--line-1); border-radius: var(--radius-m);
  }
  legend { padding: 0 var(--space-1); color: var(--fg-1); font-weight: 500; }
  input:is([type="radio"], [type="checkbox"], [type="range"]) {
    padding: 0; border: none; background: none; accent-color: var(--accent);
  }
  input:is([type="radio"], [type="checkbox"]) { flex: none; margin: 0; }
  label:has(> input:is([type="radio"], [type="checkbox"])) {
    display: flex; align-items: baseline; gap: var(--space-2); cursor: pointer;
  }
  label:has(> input:is([type="radio"], [type="checkbox"])) + label { margin-top: var(--space-1); }
  label:has(> input:is([type="radio"], [type="checkbox"]):checked) { color: var(--fg-1); }
  label > textarea, label > select, label > input:not([type="radio"], [type="checkbox"], [type="range"]) {
    display: block; margin-top: var(--space-1);
  }
  label[data-inf-recommended-label]::after, [data-inf-recommendation] {
    content: "Recommended"; display: inline-block; color: var(--accent);
    background: var(--accent-dim); border-radius: var(--radius-pill);
    padding: 0 var(--space-2); font-family: var(--font-mono); font-size: var(--text-xs);
  }
  [data-inf-recommendation] { margin-top: var(--space-1); }
  textarea { width: 100%; min-height: 64px; resize: vertical; }
  /* A question's Something else row (FI3-1002): the field the bridge opens
     under it while it is picked - one line, growing to three - indented to
     the row's words, or full width under a select. */
  textarea[data-inf-write-in-field] {
    display: block; min-height: 0; max-height: calc(3lh + 2 * var(--space-1) + 2px);
    margin: var(--space-1) 0 0 calc(13px + var(--space-2)); width: calc(100% - 13px - var(--space-2));
    padding: var(--space-1) var(--space-3); font-size: var(--text-sm); line-height: var(--leading-body);
    resize: none; field-sizing: content;
  }
  textarea[data-inf-write-in-field="select"] { margin-left: 0; width: 100%; }
  textarea[data-inf-write-in-field][hidden] { display: none; }
  button, [data-inf-action] {
    font-family: var(--font-ui); font-size: var(--text-sm); font-weight: 500;
    color: var(--fg-1); background: transparent; border: 1px solid var(--line-2);
    border-radius: var(--radius-m); padding: var(--space-1) var(--space-3); cursor: pointer;
    transition: background var(--dur-fast) var(--ease-out);
  }
  button:hover, [data-inf-action]:hover { background: var(--bg-3); }
  :focus-visible { outline: none; box-shadow: var(--focus-ring); }
`;let Kr;function ih(){return Kr??=[qd,$d,Xd,jd,Hd,th(),nh].join(`
`),Kr}function rh(e){return/<[a-z][\s\S]*>/i.test(e)?e:ah(e)}function oh(e){return e.replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;").replaceAll("'","&#39;")}function ah(e){return hd(e).map(n=>{const i=oh(n.value);return n.type==="url"&&br(n.value)?`<a href="${i}">${i}</a>`:i}).join("").split(/\n{2,}/).map(n=>`<p>${n.replaceAll(`
`,"<br>")}</p>`).join("")}const sh=8;function ch(e,t=[]){const n=rh(e);if(n!==e)return{html:n,marked:!1};const i=Pd(e),r=i.length<=tt?i.map(m=>m.start):[],s=[...new Set([...t,...r])].sort((m,y)=>y-m);let o=n;const c=[];for(const m of s){const y=/^<[a-z][^\s/>]*/i.exec(o.slice(m,m+64));if(!y)continue;const I=m+y[0].length,v=c.length,B=t.includes(m);o=`${o.slice(0,I)}${r.includes(m)?` data-inf-target="${m}"`:""}${B?` data-inf-changed="${v}"`:""}${o.slice(I)}`,B&&c.push(v)}if(c.length===0)return{html:o,marked:!1};const l=c.map(m=>`[data-inf-changed="${m}"]{anchor-name:--fm-new-${m}}`).join(""),A=c.map(m=>`<i data-inf-bar="" style="position-anchor:--fm-new-${m}"></i>`).join("");return{html:`${o}<style>${l}</style><div data-inf-bars="" aria-hidden="true">${A}</div>`,marked:!0}}const lh=`
  /* HtmlCardBody owns the vertical inset outside this auto-sized viewport.
     flow-root keeps child margins in the measured body without padding. */
  body { padding-block: 0; display: flow-root; }
  :is(p, ul, ol, dl, blockquote, h1, h2, h3, h4, h5, h6, figcaption, summary) { max-width: 66ch; }
  /* A group's caption is its own line under the strip (flex-basis 100%): a
     narrower box would let it rise beside the thumbnails, so the line keeps
     the group's width and its text keeps the measure. */
  .inf-pictures > figcaption { max-width: none; padding-right: max(0px, calc(100% - 66ch)); }
`,Ah=`
  body:has([data-inf-bars]) { padding-left: calc(var(--space-1) + ${sh}px); }
  [data-inf-bar] {
    position: absolute; left: calc(var(--space-1) - 2px); width: 2px;
    top: anchor(top); bottom: anchor(bottom);
    position-visibility: anchors-visible;
    border-radius: var(--radius-pill); background: var(--accent); pointer-events: none;
  }
`,uh=`
  [data-inf-inset] {
    float: right; clear: right; margin: 0;
    width: max(0px, calc(var(--inf-inset-width, 0px) - var(--space-1)));
    height: var(--inf-inset-height, 0px);
  }
  [data-inf-inset] ~ .inf-panel { display: flow-root; }
  [data-inf-inset] ~ :nth-child(n + 3 of :is(h1, h2, h3, h4, h5, h6, :has(:is(h1, h2, h3, h4, h5, h6)))) {
    clear: right;
  }
`;let Tr;function dh(){return Tr??=`${ih()}
${lh}
${Ah}
${uh}
${hh}`,Tr}const hh=`
  [data-inf-revision-highlight] { background-color: var(--accent-dim); box-shadow: var(--focus-ring-inset); }
`,P=e=>window.webkit.messageHandlers.cardHost.postMessage(e);let ee,ge,we,At=[];const Gr=()=>document.hasFocus()&&navigator.userActivation.isActive;let fh=0;const ut=new Map,ce=e=>ee?.contentWindow?.postMessage({fm:2,...e},"*"),Mr=e=>new Error(e);window.addEventListener("message",e=>{if(!ee||e.source!==ee.contentWindow)return;const t=tu.safeParse(e.data);if(!t.success)return;const n=t.data;if(n.type==="ready"){if(ge||!n.document)return;ge=n.document,P({type:"ready"}).catch(()=>{}),ce({type:"form",fill:Be.parse(we.fill??[]),readOnly:we.readOnly}),ce({type:"keys",pictures:!0,escape:!1}),ce({type:"width",width:we.width}),At.length>0&&ce({type:"tasks",keys:At}),ce({type:"initialize",document:ge,latePictures:!0});return}if(!(!ge||"document"in n&&n.document&&n.document!==ge))switch(n.type){case"answers":{const{questions:i,...r}=n,s=Zt.safeParse(i),o={...r,...s.success?{questions:s.data}:{questionsGap:"invalid"}};if(P({type:"answers",reading:o}).catch(()=>{}),n.seq!==void 0){const c=ut.get(n.seq);c&&(clearTimeout(c.timer),ut.delete(n.seq),c.resolve(o))}break}case"resize":ee.style.height=`${Math.max(48,Math.min(1e6,n.height))}px`,n.initialized&&P({type:"drawn",height:n.height}).catch(()=>{});break;case"pong":P({type:"pong",seq:n.seq}).catch(()=>{});break;case"request":{const i=jA.safeParse(n),r=(o,c)=>ce({type:"response",document:ge,id:n.id,...o?{ok:o,result:c}:{ok:o,error:{code:"refused",message:String(c)}}});if(!i.success||i.data.verb!=="action"||we.readOnly||!we.actions.includes(i.data.action)){r(!1,"This card cannot do that.");return}const s=i.data.value;if(s!==void 0&&new TextEncoder().encode(JSON.stringify(s)).length>KA){r(!1,"The answer is too large.");return}P({type:"action",id:i.data.action,value:s??null}).then(o=>r(!0,o),o=>r(!1,o));break}case"image":{if(!document.hasFocus()||!navigator.userActivation.isActive)return;const i=$i(n.index,n.pictures);i&&P({type:"image",...i}).catch(()=>{});break}case"demo":document.hasFocus()&&navigator.userActivation.isActive&&lu(we.body).has(n.src)&&$i(0,[n.poster])&&P({type:"demo",src:n.src,poster:n.poster,caption:n.caption,play:n.play}).catch(()=>{});break;case"link":Gr()&&br(n.href)&&P({type:"link",href:n.href}).catch(()=>{});break;case"draft":Gr()&&P({type:"draft",text:n.text}).catch(()=>{});break;case"task":n.gesture==="open"&&At.includes(n.key)&&P({type:"task",key:n.key}).catch(()=>{});break;case"entry":P({type:"mac-only"}).catch(()=>{});break}}),window.phoneCard={async mount(e){we=e;const t=e.card&&Xl(e.card)?$l(e.body):void 0,n=(e.marks??[]).map(l=>t&&l>t.at?l-t.facts.length:l);At=e.keys?.length?ZA(e.body).filter(l=>e.keys.includes(l)):[],P({type:"mounted",facts:t?.facts??null,preview:Hl(e.body)}).catch(()=>{});const i=ch(t?.body??e.body,n).html,r=new DOMParser().parseFromString(i,"text/html"),s=Array.from(r.querySelectorAll("script:not([src])"),l=>l.textContent??""),o=await P({type:"hash",scripts:s}),c=ld({csp:`${Kt(o)}; base-uri 'none'; form-action 'none'`,theme:e.theme,style:dh(),html:i});ee=window.document.createElement("iframe"),ee.title="Card body",ee.setAttribute("sandbox",uu),ee.style.cssText="display:block;width:100%;height:48px;border:0",ee.srcdoc=c,window.document.body.replaceChildren(ee)},collect(){if(!ge)return Promise.reject(Mr("This card is still drawing. Try again once it is ready."));const e=++fh;return new Promise((t,n)=>{const i=setTimeout(()=>{ut.delete(e),n(Mr("This card did not answer. Your choice was not sent."))},3e3);ut.set(e,{resolve:t,reject:n,timer:i}),ce({type:"collect",seq:e,focusUnpicked:!0})})},theme(e){ce({type:"theme",theme:e})},ping(e){ce({type:"ping",seq:e})}}})();
