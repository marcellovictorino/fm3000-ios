(function(){"use strict";var un;function d(e,t,n){function i(c,l){if(c._zod||Object.defineProperty(c,"_zod",{value:{def:l,constr:a,traits:new Set},enumerable:!1}),c._zod.traits.has(e))return;c._zod.traits.add(e),t(c,l);const A=a.prototype,m=Object.keys(A);for(let v=0;v<m.length;v++){const I=m[v];I in c||(c[I]=A[I].bind(c))}}const r=n?.Parent??Object;class s extends r{}Object.defineProperty(s,"name",{value:e});function a(c){var l;const A=n?.Parent?new s:this;i(A,c),(l=A._zod).deferred??(l.deferred=[]);for(const m of A._zod.deferred)m();return A}return Object.defineProperty(a,"init",{value:i}),Object.defineProperty(a,Symbol.hasInstance,{value:c=>n?.Parent&&c instanceof n.Parent?!0:c?._zod?.traits?.has(e)}),Object.defineProperty(a,"name",{value:e}),a}class ve extends Error{constructor(){super("Encountered Promise during synchronous parse. Use .parseAsync() instead.")}}class hn extends Error{constructor(t){super(`Encountered unidirectional transform during encode: ${t}`),this.name="ZodEncodeError"}}(un=globalThis).__zod_globalConfig??(un.__zod_globalConfig={});const ut=globalThis.__zod_globalConfig;function ne(e){return ut}function fn(e){const t=Object.values(e).filter(i=>typeof i=="number");return Object.entries(e).filter(([i,r])=>t.indexOf(+i)===-1).map(([i,r])=>r)}function ht(e,t){return typeof t=="bigint"?t.toString():t}function Ge(e){return{get value(){{const t=e();return Object.defineProperty(this,"value",{value:t}),t}}}}function ft(e){return e==null}function pt(e){const t=e.startsWith("^")?1:0,n=e.endsWith("$")?e.length-1:e.length;return e.slice(t,n)}function Hr(e,t){const n=e/t,i=Math.round(n),r=Number.EPSILON*Math.max(Math.abs(n),1);return Math.abs(n-i)<r?0:n-i}const pn=Symbol("evaluating");function C(e,t,n){let i;Object.defineProperty(e,t,{get(){if(i!==pn)return i===void 0&&(i=pn,i=n()),i},set(r){Object.defineProperty(e,t,{value:r})},configurable:!0})}function he(e,t,n){Object.defineProperty(e,t,{value:n,writable:!0,enumerable:!0,configurable:!0})}function le(...e){const t={};for(const n of e){const i=Object.getOwnPropertyDescriptors(n);Object.assign(t,i)}return Object.defineProperties({},t)}function mn(e){return JSON.stringify(e)}function qr(e){return e.toLowerCase().trim().replace(/[^\w\s-]/g,"").replace(/[\s_-]+/g,"-").replace(/^-+|-+$/g,"")}const gn="captureStackTrace"in Error?Error.captureStackTrace:(...e)=>{};function Re(e){return typeof e=="object"&&e!==null&&!Array.isArray(e)}const jr=Ge(()=>{if(ut.jitless||typeof navigator<"u"&&navigator?.userAgent?.includes("Cloudflare"))return!1;try{const e=Function;return new e(""),!0}catch{return!1}});function ye(e){if(Re(e)===!1)return!1;const t=e.constructor;if(t===void 0||typeof t!="function")return!0;const n=t.prototype;return!(Re(n)===!1||Object.prototype.hasOwnProperty.call(n,"isPrototypeOf")===!1)}function wn(e){return ye(e)?{...e}:Array.isArray(e)?[...e]:e instanceof Map?new Map(e):e instanceof Set?new Set(e):e}const Vr=new Set(["string","number","symbol"]);function ke(e){return e.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}function Ae(e,t,n){const i=new e._zod.constr(t??e._zod.def);return(!t||n?.parent)&&(i._zod.parent=e),i}function k(e){const t=e;if(!t)return{};if(typeof t=="string")return{error:()=>t};if(t?.message!==void 0){if(t?.error!==void 0)throw new Error("Cannot specify both `message` and `error` params");t.error=t.message}return delete t.message,typeof t.error=="string"?{...t,error:()=>t.error}:t}function Xr(e){return Object.keys(e).filter(t=>e[t]._zod.optin==="optional"&&e[t]._zod.optout==="optional")}const $r={safeint:[Number.MIN_SAFE_INTEGER,Number.MAX_SAFE_INTEGER],int32:[-2147483648,2147483647],uint32:[0,4294967295],float32:[-34028234663852886e22,34028234663852886e22],float64:[-Number.MAX_VALUE,Number.MAX_VALUE]};function eo(e,t){const n=e._zod.def,i=n.checks;if(i&&i.length>0)throw new Error(".pick() cannot be used on object schemas containing refinements");const s=le(e._zod.def,{get shape(){const a={};for(const c in t){if(!(c in n.shape))throw new Error(`Unrecognized key: "${c}"`);t[c]&&(a[c]=n.shape[c])}return he(this,"shape",a),a},checks:[]});return Ae(e,s)}function to(e,t){const n=e._zod.def,i=n.checks;if(i&&i.length>0)throw new Error(".omit() cannot be used on object schemas containing refinements");const s=le(e._zod.def,{get shape(){const a={...e._zod.def.shape};for(const c in t){if(!(c in n.shape))throw new Error(`Unrecognized key: "${c}"`);t[c]&&delete a[c]}return he(this,"shape",a),a},checks:[]});return Ae(e,s)}function no(e,t){if(!ye(t))throw new Error("Invalid input to extend: expected a plain object");const n=e._zod.def.checks;if(n&&n.length>0){const s=e._zod.def.shape;for(const a in t)if(Object.getOwnPropertyDescriptor(s,a)!==void 0)throw new Error("Cannot overwrite keys on object schemas containing refinements. Use `.safeExtend()` instead.")}const r=le(e._zod.def,{get shape(){const s={...e._zod.def.shape,...t};return he(this,"shape",s),s}});return Ae(e,r)}function io(e,t){if(!ye(t))throw new Error("Invalid input to safeExtend: expected a plain object");const n=le(e._zod.def,{get shape(){const i={...e._zod.def.shape,...t};return he(this,"shape",i),i}});return Ae(e,n)}function ro(e,t){if(e._zod.def.checks?.length)throw new Error(".merge() cannot be used on object schemas containing refinements. Use .safeExtend() instead.");const n=le(e._zod.def,{get shape(){const i={...e._zod.def.shape,...t._zod.def.shape};return he(this,"shape",i),i},get catchall(){return t._zod.def.catchall},checks:t._zod.def.checks??[]});return Ae(e,n)}function oo(e,t,n){const r=t._zod.def.checks;if(r&&r.length>0)throw new Error(".partial() cannot be used on object schemas containing refinements");const a=le(t._zod.def,{get shape(){const c=t._zod.def.shape,l={...c};if(n)for(const A in n){if(!(A in c))throw new Error(`Unrecognized key: "${A}"`);n[A]&&(l[A]=e?new e({type:"optional",innerType:c[A]}):c[A])}else for(const A in c)l[A]=e?new e({type:"optional",innerType:c[A]}):c[A];return he(this,"shape",l),l},checks:[]});return Ae(t,a)}function ao(e,t,n){const i=le(t._zod.def,{get shape(){const r=t._zod.def.shape,s={...r};if(n)for(const a in n){if(!(a in s))throw new Error(`Unrecognized key: "${a}"`);n[a]&&(s[a]=new e({type:"nonoptional",innerType:r[a]}))}else for(const a in r)s[a]=new e({type:"nonoptional",innerType:r[a]});return he(this,"shape",s),s}});return Ae(t,i)}function Ie(e,t=0){if(e.aborted===!0)return!0;for(let n=t;n<e.issues.length;n++)if(e.issues[n]?.continue!==!0)return!0;return!1}function so(e,t=0){if(e.aborted===!0)return!0;for(let n=t;n<e.issues.length;n++)if(e.issues[n]?.continue===!1)return!0;return!1}function xe(e,t){return t.map(n=>{var i;return(i=n).path??(i.path=[]),n.path.unshift(e),n})}function Me(e){return typeof e=="string"?e:e?.message}function ie(e,t,n){const i=e.message?e.message:Me(e.inst?._zod.def?.error?.(e))??Me(t?.error?.(e))??Me(n.customError?.(e))??Me(n.localeError?.(e))??"Invalid input",{inst:r,continue:s,input:a,...c}=e;return c.path??(c.path=[]),c.message=i,t?.reportInput&&(c.input=a),c}function mt(e){return Array.isArray(e)?"array":typeof e=="string"?"string":"unknown"}function Qe(...e){const[t,n,i]=e;return typeof t=="string"?{message:t,code:"custom",input:n,inst:i}:{...t}}const bn=(e,t)=>{e.name="$ZodError",Object.defineProperty(e,"_zod",{value:e._zod,enumerable:!1}),Object.defineProperty(e,"issues",{value:t,enumerable:!1}),e.message=JSON.stringify(t,ht,2),Object.defineProperty(e,"toString",{value:()=>e.message,enumerable:!1})},vn=d("$ZodError",bn),yn=d("$ZodError",bn,{Parent:Error});function co(e,t=n=>n.message){const n={},i=[];for(const r of e.issues)r.path.length>0?(n[r.path[0]]=n[r.path[0]]||[],n[r.path[0]].push(t(r))):i.push(t(r));return{formErrors:i,fieldErrors:n}}function lo(e,t=n=>n.message){const n={_errors:[]},i=(r,s=[])=>{for(const a of r.issues)if(a.code==="invalid_union"&&a.errors.length)a.errors.map(c=>i({issues:c},[...s,...a.path]));else if(a.code==="invalid_key")i({issues:a.issues},[...s,...a.path]);else if(a.code==="invalid_element")i({issues:a.issues},[...s,...a.path]);else{const c=[...s,...a.path];if(c.length===0)n._errors.push(t(a));else{let l=n,A=0;for(;A<c.length;){const m=c[A];A===c.length-1?(l[m]=l[m]||{_errors:[]},l[m]._errors.push(t(a))):l[m]=l[m]||{_errors:[]},l=l[m],A++}}}};return i(e),n}const gt=e=>(t,n,i,r)=>{const s=i?{...i,async:!1}:{async:!1},a=t._zod.run({value:n,issues:[]},s);if(a instanceof Promise)throw new ve;if(a.issues.length){const c=new(r?.Err??e)(a.issues.map(l=>ie(l,s,ne())));throw gn(c,r?.callee),c}return a.value},wt=e=>async(t,n,i,r)=>{const s=i?{...i,async:!0}:{async:!0};let a=t._zod.run({value:n,issues:[]},s);if(a instanceof Promise&&(a=await a),a.issues.length){const c=new(r?.Err??e)(a.issues.map(l=>ie(l,s,ne())));throw gn(c,r?.callee),c}return a.value},Je=e=>(t,n,i)=>{const r=i?{...i,async:!1}:{async:!1},s=t._zod.run({value:n,issues:[]},r);if(s instanceof Promise)throw new ve;return s.issues.length?{success:!1,error:new(e??vn)(s.issues.map(a=>ie(a,r,ne())))}:{success:!0,data:s.value}},Ao=Je(yn),Ye=e=>async(t,n,i)=>{const r=i?{...i,async:!0}:{async:!0};let s=t._zod.run({value:n,issues:[]},r);return s instanceof Promise&&(s=await s),s.issues.length?{success:!1,error:new e(s.issues.map(a=>ie(a,r,ne())))}:{success:!0,data:s.value}},uo=Ye(yn),ho=e=>(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return gt(e)(t,n,r)},fo=e=>(t,n,i)=>gt(e)(t,n,i),po=e=>async(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return wt(e)(t,n,r)},mo=e=>async(t,n,i)=>wt(e)(t,n,i),go=e=>(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return Je(e)(t,n,r)},wo=e=>(t,n,i)=>Je(e)(t,n,i),bo=e=>async(t,n,i)=>{const r=i?{...i,direction:"backward"}:{direction:"backward"};return Ye(e)(t,n,r)},vo=e=>async(t,n,i)=>Ye(e)(t,n,i),yo=/^[cC][0-9a-z]{6,}$/,ko=/^[0-9a-z]+$/,Io=/^[0-9A-HJKMNP-TV-Za-hjkmnp-tv-z]{26}$/,xo=/^[0-9a-vA-V]{20}$/,So=/^[A-Za-z0-9]{27}$/,Eo=/^[a-zA-Z0-9_-]{21}$/,Co=/^P(?:(\d+W)|(?!.*W)(?=\d|T\d)(\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+([.,]\d+)?S)?)?)$/,Bo=/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$/,kn=e=>e?new RegExp(`^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-${e}[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$`):/^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)$/,_o=/^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$/,Do="^(\\p{Extended_Pictographic}|\\p{Emoji_Component})+$";function No(){return new RegExp(Do,"u")}const Fo=/^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$/,Zo=/^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$/,Ro=/^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\/([0-9]|[1-2][0-9]|3[0-2])$/,Qo=/^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|::|([0-9a-fA-F]{1,4})?::([0-9a-fA-F]{1,4}:?){0,6})\/(12[0-8]|1[01][0-9]|[1-9]?[0-9])$/,Oo=/^$|^(?:[0-9a-zA-Z+/]{4})*(?:(?:[0-9a-zA-Z+/]{2}==)|(?:[0-9a-zA-Z+/]{3}=))?$/,In=/^[A-Za-z0-9_-]*$/,Uo=/^https?$/,Wo=/^\+[1-9]\d{6,14}$/,xn="(?:(?:\\d\\d[2468][048]|\\d\\d[13579][26]|\\d\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\d|30)|(?:02)-(?:0[1-9]|1\\d|2[0-8])))",zo=new RegExp(`^${xn}$`);function Sn(e){const t="(?:[01]\\d|2[0-3]):[0-5]\\d";return typeof e.precision=="number"?e.precision===-1?`${t}`:e.precision===0?`${t}:[0-5]\\d`:`${t}:[0-5]\\d\\.\\d{${e.precision}}`:`${t}(?::[0-5]\\d(?:\\.\\d+)?)?`}function To(e){return new RegExp(`^${Sn(e)}$`)}function Ko(e){const t=Sn({precision:e.precision}),n=["Z"];e.local&&n.push(""),e.offset&&n.push("([+-](?:[01]\\d|2[0-3]):[0-5]\\d)");const i=`${t}(?:${n.join("|")})`;return new RegExp(`^${xn}T(?:${i})$`)}const Go=e=>{const t=e?`[\\s\\S]{${e?.minimum??0},${e?.maximum??""}}`:"[\\s\\S]*";return new RegExp(`^${t}$`)},Mo=/^-?\d+$/,En=/^-?\d+(?:\.\d+)?$/,Jo=/^(?:true|false)$/i,Yo=/^null$/i,Lo=/^undefined$/i,Po=/^[^A-Z]*$/,Ho=/^[^a-z]*$/,Y=d("$ZodCheck",(e,t)=>{var n;e._zod??(e._zod={}),e._zod.def=t,(n=e._zod).onattach??(n.onattach=[])}),Cn={number:"number",bigint:"bigint",object:"date"},Bn=d("$ZodCheckLessThan",(e,t)=>{Y.init(e,t);const n=Cn[typeof t.value];e._zod.onattach.push(i=>{const r=i._zod.bag,s=(t.inclusive?r.maximum:r.exclusiveMaximum)??Number.POSITIVE_INFINITY;t.value<s&&(t.inclusive?r.maximum=t.value:r.exclusiveMaximum=t.value)}),e._zod.check=i=>{(t.inclusive?i.value<=t.value:i.value<t.value)||i.issues.push({origin:n,code:"too_big",maximum:typeof t.value=="object"?t.value.getTime():t.value,input:i.value,inclusive:t.inclusive,inst:e,continue:!t.abort})}}),_n=d("$ZodCheckGreaterThan",(e,t)=>{Y.init(e,t);const n=Cn[typeof t.value];e._zod.onattach.push(i=>{const r=i._zod.bag,s=(t.inclusive?r.minimum:r.exclusiveMinimum)??Number.NEGATIVE_INFINITY;t.value>s&&(t.inclusive?r.minimum=t.value:r.exclusiveMinimum=t.value)}),e._zod.check=i=>{(t.inclusive?i.value>=t.value:i.value>t.value)||i.issues.push({origin:n,code:"too_small",minimum:typeof t.value=="object"?t.value.getTime():t.value,input:i.value,inclusive:t.inclusive,inst:e,continue:!t.abort})}}),qo=d("$ZodCheckMultipleOf",(e,t)=>{Y.init(e,t),e._zod.onattach.push(n=>{var i;(i=n._zod.bag).multipleOf??(i.multipleOf=t.value)}),e._zod.check=n=>{if(typeof n.value!=typeof t.value)throw new Error("Cannot mix number and bigint in multiple_of check.");(typeof n.value=="bigint"?n.value%t.value===BigInt(0):Hr(n.value,t.value)===0)||n.issues.push({origin:typeof n.value,code:"not_multiple_of",divisor:t.value,input:n.value,inst:e,continue:!t.abort})}}),jo=d("$ZodCheckNumberFormat",(e,t)=>{Y.init(e,t),t.format=t.format||"float64";const n=t.format?.includes("int"),i=n?"int":"number",[r,s]=$r[t.format];e._zod.onattach.push(a=>{const c=a._zod.bag;c.format=t.format,c.minimum=r,c.maximum=s,n&&(c.pattern=Mo)}),e._zod.check=a=>{const c=a.value;if(n){if(!Number.isInteger(c)){a.issues.push({expected:i,format:t.format,code:"invalid_type",continue:!1,input:c,inst:e});return}if(!Number.isSafeInteger(c)){c>0?a.issues.push({input:c,code:"too_big",maximum:Number.MAX_SAFE_INTEGER,note:"Integers must be within the safe integer range.",inst:e,origin:i,inclusive:!0,continue:!t.abort}):a.issues.push({input:c,code:"too_small",minimum:Number.MIN_SAFE_INTEGER,note:"Integers must be within the safe integer range.",inst:e,origin:i,inclusive:!0,continue:!t.abort});return}}c<r&&a.issues.push({origin:"number",input:c,code:"too_small",minimum:r,inclusive:!0,inst:e,continue:!t.abort}),c>s&&a.issues.push({origin:"number",input:c,code:"too_big",maximum:s,inclusive:!0,inst:e,continue:!t.abort})}}),Vo=d("$ZodCheckMaxLength",(e,t)=>{var n;Y.init(e,t),(n=e._zod.def).when??(n.when=i=>{const r=i.value;return!ft(r)&&r.length!==void 0}),e._zod.onattach.push(i=>{const r=i._zod.bag.maximum??Number.POSITIVE_INFINITY;t.maximum<r&&(i._zod.bag.maximum=t.maximum)}),e._zod.check=i=>{const r=i.value;if(r.length<=t.maximum)return;const a=mt(r);i.issues.push({origin:a,code:"too_big",maximum:t.maximum,inclusive:!0,input:r,inst:e,continue:!t.abort})}}),Xo=d("$ZodCheckMinLength",(e,t)=>{var n;Y.init(e,t),(n=e._zod.def).when??(n.when=i=>{const r=i.value;return!ft(r)&&r.length!==void 0}),e._zod.onattach.push(i=>{const r=i._zod.bag.minimum??Number.NEGATIVE_INFINITY;t.minimum>r&&(i._zod.bag.minimum=t.minimum)}),e._zod.check=i=>{const r=i.value;if(r.length>=t.minimum)return;const a=mt(r);i.issues.push({origin:a,code:"too_small",minimum:t.minimum,inclusive:!0,input:r,inst:e,continue:!t.abort})}}),$o=d("$ZodCheckLengthEquals",(e,t)=>{var n;Y.init(e,t),(n=e._zod.def).when??(n.when=i=>{const r=i.value;return!ft(r)&&r.length!==void 0}),e._zod.onattach.push(i=>{const r=i._zod.bag;r.minimum=t.length,r.maximum=t.length,r.length=t.length}),e._zod.check=i=>{const r=i.value,s=r.length;if(s===t.length)return;const a=mt(r),c=s>t.length;i.issues.push({origin:a,...c?{code:"too_big",maximum:t.length}:{code:"too_small",minimum:t.length},inclusive:!0,exact:!0,input:i.value,inst:e,continue:!t.abort})}}),Le=d("$ZodCheckStringFormat",(e,t)=>{var n,i;Y.init(e,t),e._zod.onattach.push(r=>{const s=r._zod.bag;s.format=t.format,t.pattern&&(s.patterns??(s.patterns=new Set),s.patterns.add(t.pattern))}),t.pattern?(n=e._zod).check??(n.check=r=>{t.pattern.lastIndex=0,!t.pattern.test(r.value)&&r.issues.push({origin:"string",code:"invalid_format",format:t.format,input:r.value,...t.pattern?{pattern:t.pattern.toString()}:{},inst:e,continue:!t.abort})}):(i=e._zod).check??(i.check=()=>{})}),ea=d("$ZodCheckRegex",(e,t)=>{Le.init(e,t),e._zod.check=n=>{t.pattern.lastIndex=0,!t.pattern.test(n.value)&&n.issues.push({origin:"string",code:"invalid_format",format:"regex",input:n.value,pattern:t.pattern.toString(),inst:e,continue:!t.abort})}}),ta=d("$ZodCheckLowerCase",(e,t)=>{t.pattern??(t.pattern=Po),Le.init(e,t)}),na=d("$ZodCheckUpperCase",(e,t)=>{t.pattern??(t.pattern=Ho),Le.init(e,t)}),ia=d("$ZodCheckIncludes",(e,t)=>{Y.init(e,t);const n=ke(t.includes),i=new RegExp(typeof t.position=="number"?`^.{${t.position}}${n}`:n);t.pattern=i,e._zod.onattach.push(r=>{const s=r._zod.bag;s.patterns??(s.patterns=new Set),s.patterns.add(i)}),e._zod.check=r=>{r.value.includes(t.includes,t.position)||r.issues.push({origin:"string",code:"invalid_format",format:"includes",includes:t.includes,input:r.value,inst:e,continue:!t.abort})}}),ra=d("$ZodCheckStartsWith",(e,t)=>{Y.init(e,t);const n=new RegExp(`^${ke(t.prefix)}.*`);t.pattern??(t.pattern=n),e._zod.onattach.push(i=>{const r=i._zod.bag;r.patterns??(r.patterns=new Set),r.patterns.add(n)}),e._zod.check=i=>{i.value.startsWith(t.prefix)||i.issues.push({origin:"string",code:"invalid_format",format:"starts_with",prefix:t.prefix,input:i.value,inst:e,continue:!t.abort})}}),oa=d("$ZodCheckEndsWith",(e,t)=>{Y.init(e,t);const n=new RegExp(`.*${ke(t.suffix)}$`);t.pattern??(t.pattern=n),e._zod.onattach.push(i=>{const r=i._zod.bag;r.patterns??(r.patterns=new Set),r.patterns.add(n)}),e._zod.check=i=>{i.value.endsWith(t.suffix)||i.issues.push({origin:"string",code:"invalid_format",format:"ends_with",suffix:t.suffix,input:i.value,inst:e,continue:!t.abort})}}),aa=d("$ZodCheckOverwrite",(e,t)=>{Y.init(e,t),e._zod.check=n=>{n.value=t.tx(n.value)}});class sa{constructor(t=[]){this.content=[],this.indent=0,this&&(this.args=t)}indented(t){this.indent+=1,t(this),this.indent-=1}write(t){if(typeof t=="function"){t(this,{execution:"sync"}),t(this,{execution:"async"});return}const i=t.split(`
`).filter(a=>a),r=Math.min(...i.map(a=>a.length-a.trimStart().length)),s=i.map(a=>a.slice(r)).map(a=>" ".repeat(this.indent*2)+a);for(const a of s)this.content.push(a)}compile(){const t=Function,n=this?.args,r=[...(this?.content??[""]).map(s=>`  ${s}`)];return new t(...n,r.join(`
`))}}const ca={major:4,minor:4,patch:3},D=d("$ZodType",(e,t)=>{var n;e??(e={}),e._zod.def=t,e._zod.bag=e._zod.bag||{},e._zod.version=ca;const i=[...e._zod.def.checks??[]];e._zod.traits.has("$ZodCheck")&&i.unshift(e);for(const r of i)for(const s of r._zod.onattach)s(e);if(i.length===0)(n=e._zod).deferred??(n.deferred=[]),e._zod.deferred?.push(()=>{e._zod.run=e._zod.parse});else{const r=(a,c,l)=>{let A=Ie(a),m;for(const v of c){if(v._zod.def.when){if(so(a)||!v._zod.def.when(a))continue}else if(A)continue;const I=a.issues.length,y=v._zod.check(a);if(y instanceof Promise&&l?.async===!1)throw new ve;if(m||y instanceof Promise)m=(m??Promise.resolve()).then(async()=>{await y,a.issues.length!==I&&(A||(A=Ie(a,I)))});else{if(a.issues.length===I)continue;A||(A=Ie(a,I))}}return m?m.then(()=>a):a},s=(a,c,l)=>{if(Ie(a))return a.aborted=!0,a;const A=r(c,i,l);if(A instanceof Promise){if(l.async===!1)throw new ve;return A.then(m=>e._zod.parse(m,l))}return e._zod.parse(A,l)};e._zod.run=(a,c)=>{if(c.skipChecks)return e._zod.parse(a,c);if(c.direction==="backward"){const A=e._zod.parse({value:a.value,issues:[]},{...c,skipChecks:!0});return A instanceof Promise?A.then(m=>s(m,a,c)):s(A,a,c)}const l=e._zod.parse(a,c);if(l instanceof Promise){if(c.async===!1)throw new ve;return l.then(A=>r(A,i,c))}return r(l,i,c)}}C(e,"~standard",()=>({validate:r=>{try{const s=Ao(e,r);return s.success?{value:s.data}:{issues:s.error?.issues}}catch{return uo(e,r).then(a=>a.success?{value:a.data}:{issues:a.error?.issues})}},vendor:"zod",version:1}))}),bt=d("$ZodString",(e,t)=>{D.init(e,t),e._zod.pattern=[...e?._zod.bag?.patterns??[]].pop()??Go(e._zod.bag),e._zod.parse=(n,i)=>{if(t.coerce)try{n.value=String(n.value)}catch{}return typeof n.value=="string"||n.issues.push({expected:"string",code:"invalid_type",input:n.value,inst:e}),n}}),F=d("$ZodStringFormat",(e,t)=>{Le.init(e,t),bt.init(e,t)}),la=d("$ZodGUID",(e,t)=>{t.pattern??(t.pattern=Bo),F.init(e,t)}),Aa=d("$ZodUUID",(e,t)=>{if(t.version){const i={v1:1,v2:2,v3:3,v4:4,v5:5,v6:6,v7:7,v8:8}[t.version];if(i===void 0)throw new Error(`Invalid UUID version: "${t.version}"`);t.pattern??(t.pattern=kn(i))}else t.pattern??(t.pattern=kn());F.init(e,t)}),da=d("$ZodEmail",(e,t)=>{t.pattern??(t.pattern=_o),F.init(e,t)}),ua=d("$ZodURL",(e,t)=>{F.init(e,t),e._zod.check=n=>{try{const i=n.value.trim();if(!t.normalize&&t.protocol?.source===Uo.source&&!/^https?:\/\//i.test(i)){n.issues.push({code:"invalid_format",format:"url",note:"Invalid URL format",input:n.value,inst:e,continue:!t.abort});return}const r=new URL(i);t.hostname&&(t.hostname.lastIndex=0,t.hostname.test(r.hostname)||n.issues.push({code:"invalid_format",format:"url",note:"Invalid hostname",pattern:t.hostname.source,input:n.value,inst:e,continue:!t.abort})),t.protocol&&(t.protocol.lastIndex=0,t.protocol.test(r.protocol.endsWith(":")?r.protocol.slice(0,-1):r.protocol)||n.issues.push({code:"invalid_format",format:"url",note:"Invalid protocol",pattern:t.protocol.source,input:n.value,inst:e,continue:!t.abort})),t.normalize?n.value=r.href:n.value=i;return}catch{n.issues.push({code:"invalid_format",format:"url",input:n.value,inst:e,continue:!t.abort})}}}),ha=d("$ZodEmoji",(e,t)=>{t.pattern??(t.pattern=No()),F.init(e,t)}),fa=d("$ZodNanoID",(e,t)=>{t.pattern??(t.pattern=Eo),F.init(e,t)}),pa=d("$ZodCUID",(e,t)=>{t.pattern??(t.pattern=yo),F.init(e,t)}),ma=d("$ZodCUID2",(e,t)=>{t.pattern??(t.pattern=ko),F.init(e,t)}),ga=d("$ZodULID",(e,t)=>{t.pattern??(t.pattern=Io),F.init(e,t)}),wa=d("$ZodXID",(e,t)=>{t.pattern??(t.pattern=xo),F.init(e,t)}),ba=d("$ZodKSUID",(e,t)=>{t.pattern??(t.pattern=So),F.init(e,t)}),va=d("$ZodISODateTime",(e,t)=>{t.pattern??(t.pattern=Ko(t)),F.init(e,t)}),ya=d("$ZodISODate",(e,t)=>{t.pattern??(t.pattern=zo),F.init(e,t)}),ka=d("$ZodISOTime",(e,t)=>{t.pattern??(t.pattern=To(t)),F.init(e,t)}),Ia=d("$ZodISODuration",(e,t)=>{t.pattern??(t.pattern=Co),F.init(e,t)}),xa=d("$ZodIPv4",(e,t)=>{t.pattern??(t.pattern=Fo),F.init(e,t),e._zod.bag.format="ipv4"}),Sa=d("$ZodIPv6",(e,t)=>{t.pattern??(t.pattern=Zo),F.init(e,t),e._zod.bag.format="ipv6",e._zod.check=n=>{try{new URL(`http://[${n.value}]`)}catch{n.issues.push({code:"invalid_format",format:"ipv6",input:n.value,inst:e,continue:!t.abort})}}}),Ea=d("$ZodCIDRv4",(e,t)=>{t.pattern??(t.pattern=Ro),F.init(e,t)}),Ca=d("$ZodCIDRv6",(e,t)=>{t.pattern??(t.pattern=Qo),F.init(e,t),e._zod.check=n=>{const i=n.value.split("/");try{if(i.length!==2)throw new Error;const[r,s]=i;if(!s)throw new Error;const a=Number(s);if(`${a}`!==s)throw new Error;if(a<0||a>128)throw new Error;new URL(`http://[${r}]`)}catch{n.issues.push({code:"invalid_format",format:"cidrv6",input:n.value,inst:e,continue:!t.abort})}}});function Dn(e){if(e==="")return!0;if(/\s/.test(e)||e.length%4!==0)return!1;try{return atob(e),!0}catch{return!1}}const Ba=d("$ZodBase64",(e,t)=>{t.pattern??(t.pattern=Oo),F.init(e,t),e._zod.bag.contentEncoding="base64",e._zod.check=n=>{Dn(n.value)||n.issues.push({code:"invalid_format",format:"base64",input:n.value,inst:e,continue:!t.abort})}});function _a(e){if(!In.test(e))return!1;const t=e.replace(/[-_]/g,i=>i==="-"?"+":"/"),n=t.padEnd(Math.ceil(t.length/4)*4,"=");return Dn(n)}const Da=d("$ZodBase64URL",(e,t)=>{t.pattern??(t.pattern=In),F.init(e,t),e._zod.bag.contentEncoding="base64url",e._zod.check=n=>{_a(n.value)||n.issues.push({code:"invalid_format",format:"base64url",input:n.value,inst:e,continue:!t.abort})}}),Na=d("$ZodE164",(e,t)=>{t.pattern??(t.pattern=Wo),F.init(e,t)});function Fa(e,t=null){try{const n=e.split(".");if(n.length!==3)return!1;const[i]=n;if(!i)return!1;const r=JSON.parse(atob(i));return!("typ"in r&&r?.typ!=="JWT"||!r.alg||t&&(!("alg"in r)||r.alg!==t))}catch{return!1}}const Za=d("$ZodJWT",(e,t)=>{F.init(e,t),e._zod.check=n=>{Fa(n.value,t.alg)||n.issues.push({code:"invalid_format",format:"jwt",input:n.value,inst:e,continue:!t.abort})}}),Nn=d("$ZodNumber",(e,t)=>{D.init(e,t),e._zod.pattern=e._zod.bag.pattern??En,e._zod.parse=(n,i)=>{if(t.coerce)try{n.value=Number(n.value)}catch{}const r=n.value;if(typeof r=="number"&&!Number.isNaN(r)&&Number.isFinite(r))return n;const s=typeof r=="number"?Number.isNaN(r)?"NaN":Number.isFinite(r)?void 0:"Infinity":void 0;return n.issues.push({expected:"number",code:"invalid_type",input:r,inst:e,...s?{received:s}:{}}),n}}),Ra=d("$ZodNumberFormat",(e,t)=>{jo.init(e,t),Nn.init(e,t)}),Qa=d("$ZodBoolean",(e,t)=>{D.init(e,t),e._zod.pattern=Jo,e._zod.parse=(n,i)=>{if(t.coerce)try{n.value=!!n.value}catch{}const r=n.value;return typeof r=="boolean"||n.issues.push({expected:"boolean",code:"invalid_type",input:r,inst:e}),n}}),Oa=d("$ZodUndefined",(e,t)=>{D.init(e,t),e._zod.pattern=Lo,e._zod.values=new Set([void 0]),e._zod.parse=(n,i)=>{const r=n.value;return typeof r>"u"||n.issues.push({expected:"undefined",code:"invalid_type",input:r,inst:e}),n}}),Ua=d("$ZodNull",(e,t)=>{D.init(e,t),e._zod.pattern=Yo,e._zod.values=new Set([null]),e._zod.parse=(n,i)=>{const r=n.value;return r===null||n.issues.push({expected:"null",code:"invalid_type",input:r,inst:e}),n}}),Wa=d("$ZodUnknown",(e,t)=>{D.init(e,t),e._zod.parse=n=>n}),za=d("$ZodNever",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>(n.issues.push({expected:"never",code:"invalid_type",input:n.value,inst:e}),n)});function Fn(e,t,n){e.issues.length&&t.issues.push(...xe(n,e.issues)),t.value[n]=e.value}const Ta=d("$ZodArray",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>{const r=n.value;if(!Array.isArray(r))return n.issues.push({expected:"array",code:"invalid_type",input:r,inst:e}),n;n.value=Array(r.length);const s=[];for(let a=0;a<r.length;a++){const c=r[a],l=t.element._zod.run({value:c,issues:[]},i);l instanceof Promise?s.push(l.then(A=>Fn(A,n,a))):Fn(l,n,a)}return s.length?Promise.all(s).then(()=>n):n}});function Pe(e,t,n,i,r,s){const a=n in i;if(e.issues.length){if(r&&s&&!a)return;t.issues.push(...xe(n,e.issues))}if(!a&&!r){e.issues.length||t.issues.push({code:"invalid_type",expected:"nonoptional",input:void 0,path:[n]});return}e.value===void 0?a&&(t.value[n]=void 0):t.value[n]=e.value}function Zn(e){const t=Object.keys(e.shape);for(const i of t)if(!e.shape?.[i]?._zod?.traits?.has("$ZodType"))throw new Error(`Invalid element at key "${i}": expected a Zod schema`);const n=Xr(e.shape);return{...e,keys:t,keySet:new Set(t),numKeys:t.length,optionalKeys:new Set(n)}}function Rn(e,t,n,i,r,s){const a=[],c=r.keySet,l=r.catchall._zod,A=l.def.type,m=l.optin==="optional",v=l.optout==="optional";for(const I in t){if(I==="__proto__"||c.has(I))continue;if(A==="never"){a.push(I);continue}const y=l.run({value:t[I],issues:[]},i);y instanceof Promise?e.push(y.then(B=>Pe(B,n,I,t,m,v))):Pe(y,n,I,t,m,v)}return a.length&&n.issues.push({code:"unrecognized_keys",keys:a,input:t,inst:s}),e.length?Promise.all(e).then(()=>n):n}const Ka=d("$ZodObject",(e,t)=>{if(D.init(e,t),!Object.getOwnPropertyDescriptor(t,"shape")?.get){const c=t.shape;Object.defineProperty(t,"shape",{get:()=>{const l={...c};return Object.defineProperty(t,"shape",{value:l}),l}})}const i=Ge(()=>Zn(t));C(e._zod,"propValues",()=>{const c=t.shape,l={};for(const A in c){const m=c[A]._zod;if(m.values){l[A]??(l[A]=new Set);for(const v of m.values)l[A].add(v)}}return l});const r=Re,s=t.catchall;let a;e._zod.parse=(c,l)=>{a??(a=i.value);const A=c.value;if(!r(A))return c.issues.push({expected:"object",code:"invalid_type",input:A,inst:e}),c;c.value={};const m=[],v=a.shape;for(const I of a.keys){const y=v[I],B=y._zod.optin==="optional",be=y._zod.optout==="optional",T=y._zod.run({value:A[I],issues:[]},l);T instanceof Promise?m.push(T.then(dn=>Pe(dn,c,I,A,B,be))):Pe(T,c,I,A,B,be)}return s?Rn(m,A,c,l,i.value,e):m.length?Promise.all(m).then(()=>c):c}}),Ga=d("$ZodObjectJIT",(e,t)=>{Ka.init(e,t);const n=e._zod.parse,i=Ge(()=>Zn(t)),r=I=>{const y=new sa(["shape","payload","ctx"]),B=i.value,be=te=>{const U=mn(te);return`shape[${U}]._zod.run({ value: input[${U}], issues: [] }, ctx)`};y.write("const input = payload.value;");const T=Object.create(null);let dn=0;for(const te of B.keys)T[te]=`key_${dn++}`;y.write("const newResult = {};");for(const te of B.keys){const U=T[te],K=mn(te),Lr=I[te],Pr=Lr?._zod?.optin==="optional",kh=Lr?._zod?.optout==="optional";y.write(`const ${U} = ${be(te)};`),Pr&&kh?y.write(`
        if (${U}.issues.length) {
          if (${K} in input) {
            payload.issues = payload.issues.concat(${U}.issues.map(iss => ({
              ...iss,
              path: iss.path ? [${K}, ...iss.path] : [${K}]
            })));
          }
        }
        
        if (${U}.value === undefined) {
          if (${K} in input) {
            newResult[${K}] = undefined;
          }
        } else {
          newResult[${K}] = ${U}.value;
        }
        
      `):Pr?y.write(`
        if (${U}.issues.length) {
          payload.issues = payload.issues.concat(${U}.issues.map(iss => ({
            ...iss,
            path: iss.path ? [${K}, ...iss.path] : [${K}]
          })));
        }
        
        if (${U}.value === undefined) {
          if (${K} in input) {
            newResult[${K}] = undefined;
          }
        } else {
          newResult[${K}] = ${U}.value;
        }
        
      `):y.write(`
        const ${U}_present = ${K} in input;
        if (${U}.issues.length) {
          payload.issues = payload.issues.concat(${U}.issues.map(iss => ({
            ...iss,
            path: iss.path ? [${K}, ...iss.path] : [${K}]
          })));
        }
        if (!${U}_present && !${U}.issues.length) {
          payload.issues.push({
            code: "invalid_type",
            expected: "nonoptional",
            input: undefined,
            path: [${K}]
          });
        }

        if (${U}_present) {
          if (${U}.value === undefined) {
            newResult[${K}] = undefined;
          } else {
            newResult[${K}] = ${U}.value;
          }
        }

      `)}y.write("payload.value = newResult;"),y.write("return payload;");const yh=y.compile();return(te,U)=>yh(I,te,U)};let s;const a=Re,c=!ut.jitless,A=c&&jr.value,m=t.catchall;let v;e._zod.parse=(I,y)=>{v??(v=i.value);const B=I.value;return a(B)?c&&A&&y?.async===!1&&y.jitless!==!0?(s||(s=r(t.shape)),I=s(I,y),m?Rn([],B,I,y,v,e):I):n(I,y):(I.issues.push({expected:"object",code:"invalid_type",input:B,inst:e}),I)}});function Qn(e,t,n,i){for(const s of e)if(s.issues.length===0)return t.value=s.value,t;const r=e.filter(s=>!Ie(s));return r.length===1?(t.value=r[0].value,r[0]):(t.issues.push({code:"invalid_union",input:t.value,inst:n,errors:e.map(s=>s.issues.map(a=>ie(a,i,ne())))}),t)}const On=d("$ZodUnion",(e,t)=>{D.init(e,t),C(e._zod,"optin",()=>t.options.some(i=>i._zod.optin==="optional")?"optional":void 0),C(e._zod,"optout",()=>t.options.some(i=>i._zod.optout==="optional")?"optional":void 0),C(e._zod,"values",()=>{if(t.options.every(i=>i._zod.values))return new Set(t.options.flatMap(i=>Array.from(i._zod.values)))}),C(e._zod,"pattern",()=>{if(t.options.every(i=>i._zod.pattern)){const i=t.options.map(r=>r._zod.pattern);return new RegExp(`^(${i.map(r=>pt(r.source)).join("|")})$`)}});const n=t.options.length===1?t.options[0]._zod.run:null;e._zod.parse=(i,r)=>{if(n)return n(i,r);let s=!1;const a=[];for(const c of t.options){const l=c._zod.run({value:i.value,issues:[]},r);if(l instanceof Promise)a.push(l),s=!0;else{if(l.issues.length===0)return l;a.push(l)}}return s?Promise.all(a).then(c=>Qn(c,i,e,r)):Qn(a,i,e,r)}}),Ma=d("$ZodDiscriminatedUnion",(e,t)=>{t.inclusive=!1,On.init(e,t);const n=e._zod.parse;C(e._zod,"propValues",()=>{const r={};for(const s of t.options){const a=s._zod.propValues;if(!a||Object.keys(a).length===0)throw new Error(`Invalid discriminated union option at index "${t.options.indexOf(s)}"`);for(const[c,l]of Object.entries(a)){r[c]||(r[c]=new Set);for(const A of l)r[c].add(A)}}return r});const i=Ge(()=>{const r=t.options,s=new Map;for(const a of r){const c=a._zod.propValues?.[t.discriminator];if(!c||c.size===0)throw new Error(`Invalid discriminated union option at index "${t.options.indexOf(a)}"`);for(const l of c){if(s.has(l))throw new Error(`Duplicate discriminator value "${String(l)}"`);s.set(l,a)}}return s});e._zod.parse=(r,s)=>{const a=r.value;if(!Re(a))return r.issues.push({code:"invalid_type",expected:"object",input:a,inst:e}),r;const c=i.value.get(a?.[t.discriminator]);return c?c._zod.run(r,s):t.unionFallback||s.direction==="backward"?n(r,s):(r.issues.push({code:"invalid_union",errors:[],note:"No matching discriminator",discriminator:t.discriminator,options:Array.from(i.value.keys()),input:a,path:[t.discriminator],inst:e}),r)}}),Ja=d("$ZodIntersection",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>{const r=n.value,s=t.left._zod.run({value:r,issues:[]},i),a=t.right._zod.run({value:r,issues:[]},i);return s instanceof Promise||a instanceof Promise?Promise.all([s,a]).then(([l,A])=>Un(n,l,A)):Un(n,s,a)}});function vt(e,t){if(e===t)return{valid:!0,data:e};if(e instanceof Date&&t instanceof Date&&+e==+t)return{valid:!0,data:e};if(ye(e)&&ye(t)){const n=Object.keys(t),i=Object.keys(e).filter(s=>n.indexOf(s)!==-1),r={...e,...t};for(const s of i){const a=vt(e[s],t[s]);if(!a.valid)return{valid:!1,mergeErrorPath:[s,...a.mergeErrorPath]};r[s]=a.data}return{valid:!0,data:r}}if(Array.isArray(e)&&Array.isArray(t)){if(e.length!==t.length)return{valid:!1,mergeErrorPath:[]};const n=[];for(let i=0;i<e.length;i++){const r=e[i],s=t[i],a=vt(r,s);if(!a.valid)return{valid:!1,mergeErrorPath:[i,...a.mergeErrorPath]};n.push(a.data)}return{valid:!0,data:n}}return{valid:!1,mergeErrorPath:[]}}function Un(e,t,n){const i=new Map;let r;for(const c of t.issues)if(c.code==="unrecognized_keys"){r??(r=c);for(const l of c.keys)i.has(l)||i.set(l,{}),i.get(l).l=!0}else e.issues.push(c);for(const c of n.issues)if(c.code==="unrecognized_keys")for(const l of c.keys)i.has(l)||i.set(l,{}),i.get(l).r=!0;else e.issues.push(c);const s=[...i].filter(([,c])=>c.l&&c.r).map(([c])=>c);if(s.length&&r&&e.issues.push({...r,keys:s}),Ie(e))return e;const a=vt(t.value,n.value);if(!a.valid)throw new Error(`Unmergable intersection. Error path: ${JSON.stringify(a.mergeErrorPath)}`);return e.value=a.data,e}const Ya=d("$ZodRecord",(e,t)=>{D.init(e,t),e._zod.parse=(n,i)=>{const r=n.value;if(!ye(r))return n.issues.push({expected:"record",code:"invalid_type",input:r,inst:e}),n;const s=[],a=t.keyType._zod.values;if(a){n.value={};const c=new Set;for(const A of a)if(typeof A=="string"||typeof A=="number"||typeof A=="symbol"){c.add(typeof A=="number"?A.toString():A);const m=t.keyType._zod.run({value:A,issues:[]},i);if(m instanceof Promise)throw new Error("Async schemas not supported in object keys currently");if(m.issues.length){n.issues.push({code:"invalid_key",origin:"record",issues:m.issues.map(y=>ie(y,i,ne())),input:A,path:[A],inst:e});continue}const v=m.value,I=t.valueType._zod.run({value:r[A],issues:[]},i);I instanceof Promise?s.push(I.then(y=>{y.issues.length&&n.issues.push(...xe(A,y.issues)),n.value[v]=y.value})):(I.issues.length&&n.issues.push(...xe(A,I.issues)),n.value[v]=I.value)}let l;for(const A in r)c.has(A)||(l=l??[],l.push(A));l&&l.length>0&&n.issues.push({code:"unrecognized_keys",input:r,inst:e,keys:l})}else{n.value={};for(const c of Reflect.ownKeys(r)){if(c==="__proto__"||!Object.prototype.propertyIsEnumerable.call(r,c))continue;let l=t.keyType._zod.run({value:c,issues:[]},i);if(l instanceof Promise)throw new Error("Async schemas not supported in object keys currently");if(typeof c=="string"&&En.test(c)&&l.issues.length){const v=t.keyType._zod.run({value:Number(c),issues:[]},i);if(v instanceof Promise)throw new Error("Async schemas not supported in object keys currently");v.issues.length===0&&(l=v)}if(l.issues.length){t.mode==="loose"?n.value[c]=r[c]:n.issues.push({code:"invalid_key",origin:"record",issues:l.issues.map(v=>ie(v,i,ne())),input:c,path:[c],inst:e});continue}const m=t.valueType._zod.run({value:r[c],issues:[]},i);m instanceof Promise?s.push(m.then(v=>{v.issues.length&&n.issues.push(...xe(c,v.issues)),n.value[l.value]=v.value})):(m.issues.length&&n.issues.push(...xe(c,m.issues)),n.value[l.value]=m.value)}}return s.length?Promise.all(s).then(()=>n):n}}),La=d("$ZodEnum",(e,t)=>{D.init(e,t);const n=fn(t.entries),i=new Set(n);e._zod.values=i,e._zod.pattern=new RegExp(`^(${n.filter(r=>Vr.has(typeof r)).map(r=>typeof r=="string"?ke(r):r.toString()).join("|")})$`),e._zod.parse=(r,s)=>{const a=r.value;return i.has(a)||r.issues.push({code:"invalid_value",values:n,input:a,inst:e}),r}}),Pa=d("$ZodLiteral",(e,t)=>{if(D.init(e,t),t.values.length===0)throw new Error("Cannot create literal schema with no valid values");const n=new Set(t.values);e._zod.values=n,e._zod.pattern=new RegExp(`^(${t.values.map(i=>typeof i=="string"?ke(i):i?ke(i.toString()):String(i)).join("|")})$`),e._zod.parse=(i,r)=>{const s=i.value;return n.has(s)||i.issues.push({code:"invalid_value",values:t.values,input:s,inst:e}),i}}),Ha=d("$ZodTransform",(e,t)=>{D.init(e,t),e._zod.optin="optional",e._zod.parse=(n,i)=>{if(i.direction==="backward")throw new hn(e.constructor.name);const r=t.transform(n.value,n);if(i.async)return(r instanceof Promise?r:Promise.resolve(r)).then(a=>(n.value=a,n.fallback=!0,n));if(r instanceof Promise)throw new ve;return n.value=r,n.fallback=!0,n}});function Wn(e,t){return t===void 0&&(e.issues.length||e.fallback)?{issues:[],value:void 0}:e}const zn=d("$ZodOptional",(e,t)=>{D.init(e,t),e._zod.optin="optional",e._zod.optout="optional",C(e._zod,"values",()=>t.innerType._zod.values?new Set([...t.innerType._zod.values,void 0]):void 0),C(e._zod,"pattern",()=>{const n=t.innerType._zod.pattern;return n?new RegExp(`^(${pt(n.source)})?$`):void 0}),e._zod.parse=(n,i)=>{if(t.innerType._zod.optin==="optional"){const r=n.value,s=t.innerType._zod.run(n,i);return s instanceof Promise?s.then(a=>Wn(a,r)):Wn(s,r)}return n.value===void 0?n:t.innerType._zod.run(n,i)}}),qa=d("$ZodExactOptional",(e,t)=>{zn.init(e,t),C(e._zod,"values",()=>t.innerType._zod.values),C(e._zod,"pattern",()=>t.innerType._zod.pattern),e._zod.parse=(n,i)=>t.innerType._zod.run(n,i)}),ja=d("$ZodNullable",(e,t)=>{D.init(e,t),C(e._zod,"optin",()=>t.innerType._zod.optin),C(e._zod,"optout",()=>t.innerType._zod.optout),C(e._zod,"pattern",()=>{const n=t.innerType._zod.pattern;return n?new RegExp(`^(${pt(n.source)}|null)$`):void 0}),C(e._zod,"values",()=>t.innerType._zod.values?new Set([...t.innerType._zod.values,null]):void 0),e._zod.parse=(n,i)=>n.value===null?n:t.innerType._zod.run(n,i)}),Va=d("$ZodDefault",(e,t)=>{D.init(e,t),e._zod.optin="optional",C(e._zod,"values",()=>t.innerType._zod.values),e._zod.parse=(n,i)=>{if(i.direction==="backward")return t.innerType._zod.run(n,i);if(n.value===void 0)return n.value=t.defaultValue,n;const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(s=>Tn(s,t)):Tn(r,t)}});function Tn(e,t){return e.value===void 0&&(e.value=t.defaultValue),e}const Xa=d("$ZodPrefault",(e,t)=>{D.init(e,t),e._zod.optin="optional",C(e._zod,"values",()=>t.innerType._zod.values),e._zod.parse=(n,i)=>(i.direction==="backward"||n.value===void 0&&(n.value=t.defaultValue),t.innerType._zod.run(n,i))}),$a=d("$ZodNonOptional",(e,t)=>{D.init(e,t),C(e._zod,"values",()=>{const n=t.innerType._zod.values;return n?new Set([...n].filter(i=>i!==void 0)):void 0}),e._zod.parse=(n,i)=>{const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(s=>Kn(s,e)):Kn(r,e)}});function Kn(e,t){return!e.issues.length&&e.value===void 0&&e.issues.push({code:"invalid_type",expected:"nonoptional",input:e.value,inst:t}),e}const es=d("$ZodCatch",(e,t)=>{D.init(e,t),e._zod.optin="optional",C(e._zod,"optout",()=>t.innerType._zod.optout),C(e._zod,"values",()=>t.innerType._zod.values),e._zod.parse=(n,i)=>{if(i.direction==="backward")return t.innerType._zod.run(n,i);const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(s=>(n.value=s.value,s.issues.length&&(n.value=t.catchValue({...n,error:{issues:s.issues.map(a=>ie(a,i,ne()))},input:n.value}),n.issues=[],n.fallback=!0),n)):(n.value=r.value,r.issues.length&&(n.value=t.catchValue({...n,error:{issues:r.issues.map(s=>ie(s,i,ne()))},input:n.value}),n.issues=[],n.fallback=!0),n)}}),ts=d("$ZodPipe",(e,t)=>{D.init(e,t),C(e._zod,"values",()=>t.in._zod.values),C(e._zod,"optin",()=>t.in._zod.optin),C(e._zod,"optout",()=>t.out._zod.optout),C(e._zod,"propValues",()=>t.in._zod.propValues),e._zod.parse=(n,i)=>{if(i.direction==="backward"){const s=t.out._zod.run(n,i);return s instanceof Promise?s.then(a=>He(a,t.in,i)):He(s,t.in,i)}const r=t.in._zod.run(n,i);return r instanceof Promise?r.then(s=>He(s,t.out,i)):He(r,t.out,i)}});function He(e,t,n){return e.issues.length?(e.aborted=!0,e):t._zod.run({value:e.value,issues:e.issues,fallback:e.fallback},n)}const ns=d("$ZodReadonly",(e,t)=>{D.init(e,t),C(e._zod,"propValues",()=>t.innerType._zod.propValues),C(e._zod,"values",()=>t.innerType._zod.values),C(e._zod,"optin",()=>t.innerType?._zod?.optin),C(e._zod,"optout",()=>t.innerType?._zod?.optout),e._zod.parse=(n,i)=>{if(i.direction==="backward")return t.innerType._zod.run(n,i);const r=t.innerType._zod.run(n,i);return r instanceof Promise?r.then(Gn):Gn(r)}});function Gn(e){return e.value=Object.freeze(e.value),e}const is=d("$ZodLazy",(e,t)=>{D.init(e,t),C(e._zod,"innerType",()=>{const n=t;return n._cachedInner||(n._cachedInner=t.getter()),n._cachedInner}),C(e._zod,"pattern",()=>e._zod.innerType?._zod?.pattern),C(e._zod,"propValues",()=>e._zod.innerType?._zod?.propValues),C(e._zod,"optin",()=>e._zod.innerType?._zod?.optin??void 0),C(e._zod,"optout",()=>e._zod.innerType?._zod?.optout??void 0),e._zod.parse=(n,i)=>e._zod.innerType._zod.run(n,i)}),rs=d("$ZodCustom",(e,t)=>{Y.init(e,t),D.init(e,t),e._zod.parse=(n,i)=>n,e._zod.check=n=>{const i=n.value,r=t.fn(i);if(r instanceof Promise)return r.then(s=>Mn(s,n,i,e));Mn(r,n,i,e)}});function Mn(e,t,n,i){if(!e){const r={code:"custom",input:n,inst:i,path:[...i._zod.def.path??[]],continue:!i._zod.def.abort};i._zod.def.params&&(r.params=i._zod.def.params),t.issues.push(Qe(r))}}var Jn;class os{constructor(){this._map=new WeakMap,this._idmap=new Map}add(t,...n){const i=n[0];return this._map.set(t,i),i&&typeof i=="object"&&"id"in i&&this._idmap.set(i.id,t),this}clear(){return this._map=new WeakMap,this._idmap=new Map,this}remove(t){const n=this._map.get(t);return n&&typeof n=="object"&&"id"in n&&this._idmap.delete(n.id),this._map.delete(t),this}get(t){const n=t._zod.parent;if(n){const i={...this.get(n)??{}};delete i.id;const r={...i,...this._map.get(t)};return Object.keys(r).length?r:void 0}return this._map.get(t)}has(t){return this._map.has(t)}}function as(){return new os}(Jn=globalThis).__zod_globalRegistry??(Jn.__zod_globalRegistry=as());const Oe=globalThis.__zod_globalRegistry;function ss(e,t){return new e({type:"string",...k(t)})}function cs(e,t){return new e({type:"string",format:"email",check:"string_format",abort:!1,...k(t)})}function Yn(e,t){return new e({type:"string",format:"guid",check:"string_format",abort:!1,...k(t)})}function ls(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,...k(t)})}function As(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,version:"v4",...k(t)})}function ds(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,version:"v6",...k(t)})}function us(e,t){return new e({type:"string",format:"uuid",check:"string_format",abort:!1,version:"v7",...k(t)})}function hs(e,t){return new e({type:"string",format:"url",check:"string_format",abort:!1,...k(t)})}function fs(e,t){return new e({type:"string",format:"emoji",check:"string_format",abort:!1,...k(t)})}function ps(e,t){return new e({type:"string",format:"nanoid",check:"string_format",abort:!1,...k(t)})}function ms(e,t){return new e({type:"string",format:"cuid",check:"string_format",abort:!1,...k(t)})}function gs(e,t){return new e({type:"string",format:"cuid2",check:"string_format",abort:!1,...k(t)})}function ws(e,t){return new e({type:"string",format:"ulid",check:"string_format",abort:!1,...k(t)})}function bs(e,t){return new e({type:"string",format:"xid",check:"string_format",abort:!1,...k(t)})}function vs(e,t){return new e({type:"string",format:"ksuid",check:"string_format",abort:!1,...k(t)})}function ys(e,t){return new e({type:"string",format:"ipv4",check:"string_format",abort:!1,...k(t)})}function ks(e,t){return new e({type:"string",format:"ipv6",check:"string_format",abort:!1,...k(t)})}function Is(e,t){return new e({type:"string",format:"cidrv4",check:"string_format",abort:!1,...k(t)})}function xs(e,t){return new e({type:"string",format:"cidrv6",check:"string_format",abort:!1,...k(t)})}function Ss(e,t){return new e({type:"string",format:"base64",check:"string_format",abort:!1,...k(t)})}function Es(e,t){return new e({type:"string",format:"base64url",check:"string_format",abort:!1,...k(t)})}function Cs(e,t){return new e({type:"string",format:"e164",check:"string_format",abort:!1,...k(t)})}function Bs(e,t){return new e({type:"string",format:"jwt",check:"string_format",abort:!1,...k(t)})}function _s(e,t){return new e({type:"string",format:"datetime",check:"string_format",offset:!1,local:!1,precision:null,...k(t)})}function Ds(e,t){return new e({type:"string",format:"date",check:"string_format",...k(t)})}function Ns(e,t){return new e({type:"string",format:"time",check:"string_format",precision:null,...k(t)})}function Fs(e,t){return new e({type:"string",format:"duration",check:"string_format",...k(t)})}function Zs(e,t){return new e({type:"number",checks:[],...k(t)})}function Rs(e,t){return new e({type:"number",check:"number_format",abort:!1,format:"safeint",...k(t)})}function Qs(e,t){return new e({type:"boolean",...k(t)})}function Os(e,t){return new e({type:"undefined",...k(t)})}function Us(e,t){return new e({type:"null",...k(t)})}function Ws(e){return new e({type:"unknown"})}function zs(e,t){return new e({type:"never",...k(t)})}function Ln(e,t){return new Bn({check:"less_than",...k(t),value:e,inclusive:!1})}function yt(e,t){return new Bn({check:"less_than",...k(t),value:e,inclusive:!0})}function Pn(e,t){return new _n({check:"greater_than",...k(t),value:e,inclusive:!1})}function kt(e,t){return new _n({check:"greater_than",...k(t),value:e,inclusive:!0})}function Hn(e,t){return new qo({check:"multiple_of",...k(t),value:e})}function qn(e,t){return new Vo({check:"max_length",...k(t),maximum:e})}function qe(e,t){return new Xo({check:"min_length",...k(t),minimum:e})}function jn(e,t){return new $o({check:"length_equals",...k(t),length:e})}function Ts(e,t){return new ea({check:"string_format",format:"regex",...k(t),pattern:e})}function Ks(e){return new ta({check:"string_format",format:"lowercase",...k(e)})}function Gs(e){return new na({check:"string_format",format:"uppercase",...k(e)})}function Ms(e,t){return new ia({check:"string_format",format:"includes",...k(t),includes:e})}function Js(e,t){return new ra({check:"string_format",format:"starts_with",...k(t),prefix:e})}function Ys(e,t){return new oa({check:"string_format",format:"ends_with",...k(t),suffix:e})}function Se(e){return new aa({check:"overwrite",tx:e})}function Ls(e){return Se(t=>t.normalize(e))}function Ps(){return Se(e=>e.trim())}function Hs(){return Se(e=>e.toLowerCase())}function qs(){return Se(e=>e.toUpperCase())}function js(){return Se(e=>qr(e))}function Vs(e,t,n){return new e({type:"array",element:t,...k(n)})}function Xs(e,t,n){return new e({type:"custom",check:"custom",fn:t,...k(n)})}function $s(e,t){const n=ec(i=>(i.addIssue=r=>{if(typeof r=="string")i.issues.push(Qe(r,i.value,n._zod.def));else{const s=r;s.fatal&&(s.continue=!1),s.code??(s.code="custom"),s.input??(s.input=i.value),s.inst??(s.inst=n),s.continue??(s.continue=!n._zod.def.abort),i.issues.push(Qe(s))}},e(i.value,i)),t);return n}function ec(e,t){const n=new Y({check:"custom",...k(t)});return n._zod.check=e,n}function Vn(e){let t=e?.target??"draft-2020-12";return t==="draft-4"&&(t="draft-04"),t==="draft-7"&&(t="draft-07"),{processors:e.processors??{},metadataRegistry:e?.metadata??Oe,target:t,unrepresentable:e?.unrepresentable??"throw",override:e?.override??(()=>{}),io:e?.io??"output",counter:0,seen:new Map,cycles:e?.cycles??"ref",reused:e?.reused??"inline",external:e?.external??void 0}}function W(e,t,n={path:[],schemaPath:[]}){var i;const r=e._zod.def,s=t.seen.get(e);if(s)return s.count++,n.schemaPath.includes(e)&&(s.cycle=n.path),s.schema;const a={schema:{},count:1,cycle:void 0,path:n.path};t.seen.set(e,a);const c=e._zod.toJSONSchema?.();if(c)a.schema=c;else{const m={...n,schemaPath:[...n.schemaPath,e],path:n.path};if(e._zod.processJSONSchema)e._zod.processJSONSchema(t,a.schema,m);else{const I=a.schema,y=t.processors[r.type];if(!y)throw new Error(`[toJSONSchema]: Non-representable type encountered: ${r.type}`);y(e,t,I,m)}const v=e._zod.parent;v&&(a.ref||(a.ref=v),W(v,t,m),t.seen.get(v).isParent=!0)}const l=t.metadataRegistry.get(e);return l&&Object.assign(a.schema,l),t.io==="input"&&M(e)&&(delete a.schema.examples,delete a.schema.default),t.io==="input"&&"_prefault"in a.schema&&((i=a.schema).default??(i.default=a.schema._prefault)),delete a.schema._prefault,t.seen.get(e).schema}function Xn(e,t){const n=e.seen.get(t);if(!n)throw new Error("Unprocessed schema. This is a bug in Zod.");const i=new Map;for(const a of e.seen.entries()){const c=e.metadataRegistry.get(a[0])?.id;if(c){const l=i.get(c);if(l&&l!==a[0])throw new Error(`Duplicate schema id "${c}" detected during JSON Schema conversion. Two different schemas cannot share the same id when converted together.`);i.set(c,a[0])}}const r=a=>{const c=e.target==="draft-2020-12"?"$defs":"definitions";if(e.external){const v=e.external.registry.get(a[0])?.id,I=e.external.uri??(B=>B);if(v)return{ref:I(v)};const y=a[1].defId??a[1].schema.id??`schema${e.counter++}`;return a[1].defId=y,{defId:y,ref:`${I("__shared")}#/${c}/${y}`}}if(a[1]===n)return{ref:"#"};const A=`#/${c}/`,m=a[1].schema.id??`__schema${e.counter++}`;return{defId:m,ref:A+m}},s=a=>{if(a[1].schema.$ref)return;const c=a[1],{ref:l,defId:A}=r(a);c.def={...c.schema},A&&(c.defId=A);const m=c.schema;for(const v in m)delete m[v];m.$ref=l};if(e.cycles==="throw")for(const a of e.seen.entries()){const c=a[1];if(c.cycle)throw new Error(`Cycle detected: #/${c.cycle?.join("/")}/<root>

Set the \`cycles\` parameter to \`"ref"\` to resolve cyclical schemas with defs.`)}for(const a of e.seen.entries()){const c=a[1];if(t===a[0]){s(a);continue}if(e.external){const A=e.external.registry.get(a[0])?.id;if(t!==a[0]&&A){s(a);continue}}if(e.metadataRegistry.get(a[0])?.id){s(a);continue}if(c.cycle){s(a);continue}if(c.count>1&&e.reused==="ref"){s(a);continue}}}function $n(e,t){const n=e.seen.get(t);if(!n)throw new Error("Unprocessed schema. This is a bug in Zod.");const i=c=>{const l=e.seen.get(c);if(l.ref===null)return;const A=l.def??l.schema,m={...A},v=l.ref;if(l.ref=null,v){i(v);const y=e.seen.get(v),B=y.schema;if(B.$ref&&(e.target==="draft-07"||e.target==="draft-04"||e.target==="openapi-3.0")?(A.allOf=A.allOf??[],A.allOf.push(B)):Object.assign(A,B),Object.assign(A,m),c._zod.parent===v)for(const T in A)T==="$ref"||T==="allOf"||T in m||delete A[T];if(B.$ref&&y.def)for(const T in A)T==="$ref"||T==="allOf"||T in y.def&&JSON.stringify(A[T])===JSON.stringify(y.def[T])&&delete A[T]}const I=c._zod.parent;if(I&&I!==v){i(I);const y=e.seen.get(I);if(y?.schema.$ref&&(A.$ref=y.schema.$ref,y.def))for(const B in A)B==="$ref"||B==="allOf"||B in y.def&&JSON.stringify(A[B])===JSON.stringify(y.def[B])&&delete A[B]}e.override({zodSchema:c,jsonSchema:A,path:l.path??[]})};for(const c of[...e.seen.entries()].reverse())i(c[0]);const r={};if(e.target==="draft-2020-12"?r.$schema="https://json-schema.org/draft/2020-12/schema":e.target==="draft-07"?r.$schema="http://json-schema.org/draft-07/schema#":e.target==="draft-04"?r.$schema="http://json-schema.org/draft-04/schema#":e.target,e.external?.uri){const c=e.external.registry.get(t)?.id;if(!c)throw new Error("Schema is missing an `id` property");r.$id=e.external.uri(c)}Object.assign(r,n.def??n.schema);const s=e.metadataRegistry.get(t)?.id;s!==void 0&&r.id===s&&delete r.id;const a=e.external?.defs??{};for(const c of e.seen.entries()){const l=c[1];l.def&&l.defId&&(l.def.id===l.defId&&delete l.def.id,a[l.defId]=l.def)}e.external||Object.keys(a).length>0&&(e.target==="draft-2020-12"?r.$defs=a:r.definitions=a);try{const c=JSON.parse(JSON.stringify(r));return Object.defineProperty(c,"~standard",{value:{...t["~standard"],jsonSchema:{input:je(t,"input",e.processors),output:je(t,"output",e.processors)}},enumerable:!1,writable:!1}),c}catch{throw new Error("Error converting schema to JSON.")}}function M(e,t){const n=t??{seen:new Set};if(n.seen.has(e))return!1;n.seen.add(e);const i=e._zod.def;if(i.type==="transform")return!0;if(i.type==="array")return M(i.element,n);if(i.type==="set")return M(i.valueType,n);if(i.type==="lazy")return M(i.getter(),n);if(i.type==="promise"||i.type==="optional"||i.type==="nonoptional"||i.type==="nullable"||i.type==="readonly"||i.type==="default"||i.type==="prefault")return M(i.innerType,n);if(i.type==="intersection")return M(i.left,n)||M(i.right,n);if(i.type==="record"||i.type==="map")return M(i.keyType,n)||M(i.valueType,n);if(i.type==="pipe")return e._zod.traits.has("$ZodCodec")?!0:M(i.in,n)||M(i.out,n);if(i.type==="object"){for(const r in i.shape)if(M(i.shape[r],n))return!0;return!1}if(i.type==="union"){for(const r of i.options)if(M(r,n))return!0;return!1}if(i.type==="tuple"){for(const r of i.items)if(M(r,n))return!0;return!!(i.rest&&M(i.rest,n))}return!1}const tc=(e,t={})=>n=>{const i=Vn({...n,processors:t});return W(e,i),Xn(i,e),$n(i,e)},je=(e,t,n={})=>i=>{const{libraryOptions:r,target:s}=i??{},a=Vn({...r??{},target:s,io:t,processors:n});return W(e,a),Xn(a,e),$n(a,e)},nc={guid:"uuid",url:"uri",datetime:"date-time",json_string:"json-string",regex:""},ic=(e,t,n,i)=>{const r=n;r.type="string";const{minimum:s,maximum:a,format:c,patterns:l,contentEncoding:A}=e._zod.bag;if(typeof s=="number"&&(r.minLength=s),typeof a=="number"&&(r.maxLength=a),c&&(r.format=nc[c]??c,r.format===""&&delete r.format,c==="time"&&delete r.format),A&&(r.contentEncoding=A),l&&l.size>0){const m=[...l];m.length===1?r.pattern=m[0].source:m.length>1&&(r.allOf=[...m.map(v=>({...t.target==="draft-07"||t.target==="draft-04"||t.target==="openapi-3.0"?{type:"string"}:{},pattern:v.source}))])}},rc=(e,t,n,i)=>{const r=n,{minimum:s,maximum:a,format:c,multipleOf:l,exclusiveMaximum:A,exclusiveMinimum:m}=e._zod.bag;typeof c=="string"&&c.includes("int")?r.type="integer":r.type="number";const v=typeof m=="number"&&m>=(s??Number.NEGATIVE_INFINITY),I=typeof A=="number"&&A<=(a??Number.POSITIVE_INFINITY),y=t.target==="draft-04"||t.target==="openapi-3.0";v?y?(r.minimum=m,r.exclusiveMinimum=!0):r.exclusiveMinimum=m:typeof s=="number"&&(r.minimum=s),I?y?(r.maximum=A,r.exclusiveMaximum=!0):r.exclusiveMaximum=A:typeof a=="number"&&(r.maximum=a),typeof l=="number"&&(r.multipleOf=l)},oc=(e,t,n,i)=>{n.type="boolean"},ac=(e,t,n,i)=>{t.target==="openapi-3.0"?(n.type="string",n.nullable=!0,n.enum=[null]):n.type="null"},sc=(e,t,n,i)=>{if(t.unrepresentable==="throw")throw new Error("Undefined cannot be represented in JSON Schema")},cc=(e,t,n,i)=>{n.not={}},lc=(e,t,n,i)=>{},Ac=(e,t,n,i)=>{const r=e._zod.def,s=fn(r.entries);s.every(a=>typeof a=="number")&&(n.type="number"),s.every(a=>typeof a=="string")&&(n.type="string"),n.enum=s},dc=(e,t,n,i)=>{const r=e._zod.def,s=[];for(const a of r.values)if(a===void 0){if(t.unrepresentable==="throw")throw new Error("Literal `undefined` cannot be represented in JSON Schema")}else if(typeof a=="bigint"){if(t.unrepresentable==="throw")throw new Error("BigInt literals cannot be represented in JSON Schema");s.push(Number(a))}else s.push(a);if(s.length!==0)if(s.length===1){const a=s[0];n.type=a===null?"null":typeof a,t.target==="draft-04"||t.target==="openapi-3.0"?n.enum=[a]:n.const=a}else s.every(a=>typeof a=="number")&&(n.type="number"),s.every(a=>typeof a=="string")&&(n.type="string"),s.every(a=>typeof a=="boolean")&&(n.type="boolean"),s.every(a=>a===null)&&(n.type="null"),n.enum=s},uc=(e,t,n,i)=>{if(t.unrepresentable==="throw")throw new Error("Custom types cannot be represented in JSON Schema")},hc=(e,t,n,i)=>{if(t.unrepresentable==="throw")throw new Error("Transforms cannot be represented in JSON Schema")},fc=(e,t,n,i)=>{const r=n,s=e._zod.def,{minimum:a,maximum:c}=e._zod.bag;typeof a=="number"&&(r.minItems=a),typeof c=="number"&&(r.maxItems=c),r.type="array",r.items=W(s.element,t,{...i,path:[...i.path,"items"]})},pc=(e,t,n,i)=>{const r=n,s=e._zod.def;r.type="object",r.properties={};const a=s.shape;for(const A in a)r.properties[A]=W(a[A],t,{...i,path:[...i.path,"properties",A]});const c=new Set(Object.keys(a)),l=new Set([...c].filter(A=>{const m=s.shape[A]._zod;return t.io==="input"?m.optin===void 0:m.optout===void 0}));l.size>0&&(r.required=Array.from(l)),s.catchall?._zod.def.type==="never"?r.additionalProperties=!1:s.catchall?s.catchall&&(r.additionalProperties=W(s.catchall,t,{...i,path:[...i.path,"additionalProperties"]})):t.io==="output"&&(r.additionalProperties=!1)},mc=(e,t,n,i)=>{const r=e._zod.def,s=r.inclusive===!1,a=r.options.map((c,l)=>W(c,t,{...i,path:[...i.path,s?"oneOf":"anyOf",l]}));s?n.oneOf=a:n.anyOf=a},gc=(e,t,n,i)=>{const r=e._zod.def,s=W(r.left,t,{...i,path:[...i.path,"allOf",0]}),a=W(r.right,t,{...i,path:[...i.path,"allOf",1]}),c=A=>"allOf"in A&&Object.keys(A).length===1,l=[...c(s)?s.allOf:[s],...c(a)?a.allOf:[a]];n.allOf=l},wc=(e,t,n,i)=>{const r=n,s=e._zod.def;r.type="object";const a=s.keyType,l=a._zod.bag?.patterns;if(s.mode==="loose"&&l&&l.size>0){const m=W(s.valueType,t,{...i,path:[...i.path,"patternProperties","*"]});r.patternProperties={};for(const v of l)r.patternProperties[v.source]=m}else(t.target==="draft-07"||t.target==="draft-2020-12")&&(r.propertyNames=W(s.keyType,t,{...i,path:[...i.path,"propertyNames"]})),r.additionalProperties=W(s.valueType,t,{...i,path:[...i.path,"additionalProperties"]});const A=a._zod.values;if(A){const m=[...A].filter(v=>typeof v=="string"||typeof v=="number");m.length>0&&(r.required=m)}},bc=(e,t,n,i)=>{const r=e._zod.def,s=W(r.innerType,t,i),a=t.seen.get(e);t.target==="openapi-3.0"?(a.ref=r.innerType,n.nullable=!0):n.anyOf=[s,{type:"null"}]},vc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType},yc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType,n.default=JSON.parse(JSON.stringify(r.defaultValue))},kc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType,t.io==="input"&&(n._prefault=JSON.parse(JSON.stringify(r.defaultValue)))},Ic=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType;let a;try{a=r.catchValue(void 0)}catch{throw new Error("Dynamic catch values are not supported in JSON Schema")}n.default=a},xc=(e,t,n,i)=>{const r=e._zod.def,s=r.in._zod.traits.has("$ZodTransform"),a=t.io==="input"?s?r.out:r.in:r.out;W(a,t,i);const c=t.seen.get(e);c.ref=a},Sc=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType,n.readOnly=!0},ei=(e,t,n,i)=>{const r=e._zod.def;W(r.innerType,t,i);const s=t.seen.get(e);s.ref=r.innerType},Ec=(e,t,n,i)=>{const r=e._zod.innerType;W(r,t,i);const s=t.seen.get(e);s.ref=r},Cc=d("ZodISODateTime",(e,t)=>{va.init(e,t),Z.init(e,t)});function Bc(e){return _s(Cc,e)}const _c=d("ZodISODate",(e,t)=>{ya.init(e,t),Z.init(e,t)});function Dc(e){return Ds(_c,e)}const Nc=d("ZodISOTime",(e,t)=>{ka.init(e,t),Z.init(e,t)});function Fc(e){return Ns(Nc,e)}const Zc=d("ZodISODuration",(e,t)=>{Ia.init(e,t),Z.init(e,t)});function Rc(e){return Fs(Zc,e)}const H=d("ZodError",(e,t)=>{vn.init(e,t),e.name="ZodError",Object.defineProperties(e,{format:{value:n=>lo(e,n)},flatten:{value:n=>co(e,n)},addIssue:{value:n=>{e.issues.push(n),e.message=JSON.stringify(e.issues,ht,2)}},addIssues:{value:n=>{e.issues.push(...n),e.message=JSON.stringify(e.issues,ht,2)}},isEmpty:{get(){return e.issues.length===0}}})},{Parent:Error}),Qc=gt(H),Oc=wt(H),Uc=Je(H),Wc=Ye(H),zc=ho(H),Tc=fo(H),Kc=po(H),Gc=mo(H),Mc=go(H),Jc=wo(H),Yc=bo(H),Lc=vo(H),ti=new WeakMap;function Ue(e,t,n){const i=Object.getPrototypeOf(e);let r=ti.get(i);if(r||(r=new Set,ti.set(i,r)),!r.has(t)){r.add(t);for(const s in n){const a=n[s];Object.defineProperty(i,s,{configurable:!0,enumerable:!1,get(){const c=a.bind(this);return Object.defineProperty(this,s,{configurable:!0,writable:!0,enumerable:!0,value:c}),c},set(c){Object.defineProperty(this,s,{configurable:!0,writable:!0,enumerable:!0,value:c})}})}}}const N=d("ZodType",(e,t)=>(D.init(e,t),Object.assign(e["~standard"],{jsonSchema:{input:je(e,"input"),output:je(e,"output")}}),e.toJSONSchema=tc(e,{}),e.def=t,e.type=t.type,Object.defineProperty(e,"_def",{value:t}),e.parse=(n,i)=>Qc(e,n,i,{callee:e.parse}),e.safeParse=(n,i)=>Uc(e,n,i),e.parseAsync=async(n,i)=>Oc(e,n,i,{callee:e.parseAsync}),e.safeParseAsync=async(n,i)=>Wc(e,n,i),e.spa=e.safeParseAsync,e.encode=(n,i)=>zc(e,n,i),e.decode=(n,i)=>Tc(e,n,i),e.encodeAsync=async(n,i)=>Kc(e,n,i),e.decodeAsync=async(n,i)=>Gc(e,n,i),e.safeEncode=(n,i)=>Mc(e,n,i),e.safeDecode=(n,i)=>Jc(e,n,i),e.safeEncodeAsync=async(n,i)=>Yc(e,n,i),e.safeDecodeAsync=async(n,i)=>Lc(e,n,i),Ue(e,"ZodType",{check(...n){const i=this.def;return this.clone(le(i,{checks:[...i.checks??[],...n.map(r=>typeof r=="function"?{_zod:{check:r,def:{check:"custom"},onattach:[]}}:r)]}),{parent:!0})},with(...n){return this.check(...n)},clone(n,i){return Ae(this,n,i)},brand(){return this},register(n,i){return n.add(this,i),this},refine(n,i){return this.check(Tl(n,i))},superRefine(n,i){return this.check(Kl(n,i))},overwrite(n){return this.check(Se(n))},optional(){return Ai(this)},exactOptional(){return El(this)},nullable(){return di(this)},nullish(){return Ai(di(this))},nonoptional(n){return Fl(this,n)},array(){return w(this)},or(n){return q([this,n])},and(n){return yl(this,n)},transform(n){return hi(this,xl(n))},default(n){return _l(this,n)},prefault(n){return Nl(this,n)},catch(n){return Rl(this,n)},pipe(n){return hi(this,n)},readonly(){return Ul(this)},describe(n){const i=this.clone();return Oe.add(i,{description:n}),i},meta(...n){if(n.length===0)return Oe.get(this);const i=this.clone();return Oe.add(i,n[0]),i},isOptional(){return this.safeParse(void 0).success},isNullable(){return this.safeParse(null).success},apply(n){return n(this)}}),Object.defineProperty(e,"description",{get(){return Oe.get(e)?.description},configurable:!0}),e)),ni=d("_ZodString",(e,t)=>{bt.init(e,t),N.init(e,t),e._zod.processJSONSchema=(i,r,s)=>ic(e,i,r);const n=e._zod.bag;e.format=n.format??null,e.minLength=n.minimum??null,e.maxLength=n.maximum??null,Ue(e,"_ZodString",{regex(...i){return this.check(Ts(...i))},includes(...i){return this.check(Ms(...i))},startsWith(...i){return this.check(Js(...i))},endsWith(...i){return this.check(Ys(...i))},min(...i){return this.check(qe(...i))},max(...i){return this.check(qn(...i))},length(...i){return this.check(jn(...i))},nonempty(...i){return this.check(qe(1,...i))},lowercase(i){return this.check(Ks(i))},uppercase(i){return this.check(Gs(i))},trim(){return this.check(Ps())},normalize(...i){return this.check(Ls(...i))},toLowerCase(){return this.check(Hs())},toUpperCase(){return this.check(qs())},slugify(){return this.check(js())}})}),Pc=d("ZodString",(e,t)=>{bt.init(e,t),ni.init(e,t),e.email=n=>e.check(cs(Hc,n)),e.url=n=>e.check(hs(qc,n)),e.jwt=n=>e.check(Bs(Al,n)),e.emoji=n=>e.check(fs(jc,n)),e.guid=n=>e.check(Yn(ii,n)),e.uuid=n=>e.check(ls(Ve,n)),e.uuidv4=n=>e.check(As(Ve,n)),e.uuidv6=n=>e.check(ds(Ve,n)),e.uuidv7=n=>e.check(us(Ve,n)),e.nanoid=n=>e.check(ps(Vc,n)),e.guid=n=>e.check(Yn(ii,n)),e.cuid=n=>e.check(ms(Xc,n)),e.cuid2=n=>e.check(gs($c,n)),e.ulid=n=>e.check(ws(el,n)),e.base64=n=>e.check(Ss(sl,n)),e.base64url=n=>e.check(Es(cl,n)),e.xid=n=>e.check(bs(tl,n)),e.ksuid=n=>e.check(vs(nl,n)),e.ipv4=n=>e.check(ys(il,n)),e.ipv6=n=>e.check(ks(rl,n)),e.cidrv4=n=>e.check(Is(ol,n)),e.cidrv6=n=>e.check(xs(al,n)),e.e164=n=>e.check(Cs(ll,n)),e.datetime=n=>e.check(Bc(n)),e.date=n=>e.check(Dc(n)),e.time=n=>e.check(Fc(n)),e.duration=n=>e.check(Rc(n))});function o(e){return ss(Pc,e)}const Z=d("ZodStringFormat",(e,t)=>{F.init(e,t),ni.init(e,t)}),Hc=d("ZodEmail",(e,t)=>{da.init(e,t),Z.init(e,t)}),ii=d("ZodGUID",(e,t)=>{la.init(e,t),Z.init(e,t)}),Ve=d("ZodUUID",(e,t)=>{Aa.init(e,t),Z.init(e,t)}),qc=d("ZodURL",(e,t)=>{ua.init(e,t),Z.init(e,t)}),jc=d("ZodEmoji",(e,t)=>{ha.init(e,t),Z.init(e,t)}),Vc=d("ZodNanoID",(e,t)=>{fa.init(e,t),Z.init(e,t)}),Xc=d("ZodCUID",(e,t)=>{pa.init(e,t),Z.init(e,t)}),$c=d("ZodCUID2",(e,t)=>{ma.init(e,t),Z.init(e,t)}),el=d("ZodULID",(e,t)=>{ga.init(e,t),Z.init(e,t)}),tl=d("ZodXID",(e,t)=>{wa.init(e,t),Z.init(e,t)}),nl=d("ZodKSUID",(e,t)=>{ba.init(e,t),Z.init(e,t)}),il=d("ZodIPv4",(e,t)=>{xa.init(e,t),Z.init(e,t)}),rl=d("ZodIPv6",(e,t)=>{Sa.init(e,t),Z.init(e,t)}),ol=d("ZodCIDRv4",(e,t)=>{Ea.init(e,t),Z.init(e,t)}),al=d("ZodCIDRv6",(e,t)=>{Ca.init(e,t),Z.init(e,t)}),sl=d("ZodBase64",(e,t)=>{Ba.init(e,t),Z.init(e,t)}),cl=d("ZodBase64URL",(e,t)=>{Da.init(e,t),Z.init(e,t)}),ll=d("ZodE164",(e,t)=>{Na.init(e,t),Z.init(e,t)}),Al=d("ZodJWT",(e,t)=>{Za.init(e,t),Z.init(e,t)}),ri=d("ZodNumber",(e,t)=>{Nn.init(e,t),N.init(e,t),e._zod.processJSONSchema=(i,r,s)=>rc(e,i,r),Ue(e,"ZodNumber",{gt(i,r){return this.check(Pn(i,r))},gte(i,r){return this.check(kt(i,r))},min(i,r){return this.check(kt(i,r))},lt(i,r){return this.check(Ln(i,r))},lte(i,r){return this.check(yt(i,r))},max(i,r){return this.check(yt(i,r))},int(i){return this.check(oi(i))},safe(i){return this.check(oi(i))},positive(i){return this.check(Pn(0,i))},nonnegative(i){return this.check(kt(0,i))},negative(i){return this.check(Ln(0,i))},nonpositive(i){return this.check(yt(0,i))},multipleOf(i,r){return this.check(Hn(i,r))},step(i,r){return this.check(Hn(i,r))},finite(){return this}});const n=e._zod.bag;e.minValue=Math.max(n.minimum??Number.NEGATIVE_INFINITY,n.exclusiveMinimum??Number.NEGATIVE_INFINITY)??null,e.maxValue=Math.min(n.maximum??Number.POSITIVE_INFINITY,n.exclusiveMaximum??Number.POSITIVE_INFINITY)??null,e.isInt=(n.format??"").includes("int")||Number.isSafeInteger(n.multipleOf??.5),e.isFinite=!0,e.format=n.format??null});function u(e){return Zs(ri,e)}const dl=d("ZodNumberFormat",(e,t)=>{Ra.init(e,t),ri.init(e,t)});function oi(e){return Rs(dl,e)}const ul=d("ZodBoolean",(e,t)=>{Qa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>oc(e,n,i)});function S(e){return Qs(ul,e)}const hl=d("ZodUndefined",(e,t)=>{Oa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>sc(e,n)});function fl(e){return Os(hl,e)}const pl=d("ZodNull",(e,t)=>{Ua.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>ac(e,n,i)});function Xe(e){return Us(pl,e)}const ml=d("ZodUnknown",(e,t)=>{Wa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>lc()});function j(){return Ws(ml)}const gl=d("ZodNever",(e,t)=>{za.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>cc(e,n,i)});function Ee(e){return zs(gl,e)}const wl=d("ZodArray",(e,t)=>{Ta.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>fc(e,n,i,r),e.element=t.element,Ue(e,"ZodArray",{min(n,i){return this.check(qe(n,i))},nonempty(n){return this.check(qe(1,n))},max(n,i){return this.check(qn(n,i))},length(n,i){return this.check(jn(n,i))},unwrap(){return this.element}})});function w(e,t){return Vs(wl,e,t)}const ai=d("ZodObject",(e,t)=>{Ga.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>pc(e,n,i,r),C(e,"shape",()=>t.shape),Ue(e,"ZodObject",{keyof(){return g(Object.keys(this._zod.def.shape))},catchall(n){return this.clone({...this._zod.def,catchall:n})},passthrough(){return this.clone({...this._zod.def,catchall:j()})},loose(){return this.clone({...this._zod.def,catchall:j()})},strict(){return this.clone({...this._zod.def,catchall:Ee()})},strip(){return this.clone({...this._zod.def,catchall:void 0})},extend(n){return no(this,n)},safeExtend(n){return io(this,n)},merge(n){return ro(this,n)},pick(n){return eo(this,n)},omit(n){return to(this,n)},partial(...n){return oo(li,this,n[0])},required(...n){return ao(ui,this,n[0])}})});function h(e,t){const n={type:"object",shape:e??{},...k(t)};return new ai(n)}function b(e,t){return new ai({type:"object",shape:e,catchall:Ee(),...k(t)})}const si=d("ZodUnion",(e,t)=>{On.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>mc(e,n,i,r),e.options=t.options});function q(e,t){return new si({type:"union",options:e,...k(t)})}const bl=d("ZodDiscriminatedUnion",(e,t)=>{si.init(e,t),Ma.init(e,t)});function R(e,t,n){return new bl({type:"union",options:t,discriminator:e,...k(n)})}const vl=d("ZodIntersection",(e,t)=>{Ja.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>gc(e,n,i,r)});function yl(e,t){return new vl({type:"intersection",left:e,right:t})}const ci=d("ZodRecord",(e,t)=>{Ya.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>wc(e,n,i,r),e.keyType=t.keyType,e.valueType=t.valueType});function V(e,t,n){return!t||!t._zod?new ci({type:"record",keyType:o(),valueType:e,...k(t)}):new ci({type:"record",keyType:e,valueType:t,...k(n)})}const It=d("ZodEnum",(e,t)=>{La.init(e,t),N.init(e,t),e._zod.processJSONSchema=(i,r,s)=>Ac(e,i,r),e.enum=t.entries,e.options=Object.values(t.entries);const n=new Set(Object.keys(t.entries));e.extract=(i,r)=>{const s={};for(const a of i)if(n.has(a))s[a]=t.entries[a];else throw new Error(`Key ${a} not found in enum`);return new It({...t,checks:[],...k(r),entries:s})},e.exclude=(i,r)=>{const s={...t.entries};for(const a of i)if(n.has(a))delete s[a];else throw new Error(`Key ${a} not found in enum`);return new It({...t,checks:[],...k(r),entries:s})}});function g(e,t){const n=Array.isArray(e)?Object.fromEntries(e.map(i=>[i,i])):e;return new It({type:"enum",entries:n,...k(t)})}const kl=d("ZodLiteral",(e,t)=>{Pa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>dc(e,n,i),e.values=new Set(t.values),Object.defineProperty(e,"value",{get(){if(t.values.length>1)throw new Error("This schema contains multiple valid literal values. Use `.values` instead.");return t.values[0]}})});function p(e,t){return new kl({type:"literal",values:Array.isArray(e)?e:[e],...k(t)})}const Il=d("ZodTransform",(e,t)=>{Ha.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>hc(e,n),e._zod.parse=(n,i)=>{if(i.direction==="backward")throw new hn(e.constructor.name);n.addIssue=s=>{if(typeof s=="string")n.issues.push(Qe(s,n.value,t));else{const a=s;a.fatal&&(a.continue=!1),a.code??(a.code="custom"),a.input??(a.input=n.value),a.inst??(a.inst=e),n.issues.push(Qe(a))}};const r=t.transform(n.value,n);return r instanceof Promise?r.then(s=>(n.value=s,n.fallback=!0,n)):(n.value=r,n.fallback=!0,n)}});function xl(e){return new Il({type:"transform",transform:e})}const li=d("ZodOptional",(e,t)=>{zn.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>ei(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function Ai(e){return new li({type:"optional",innerType:e})}const Sl=d("ZodExactOptional",(e,t)=>{qa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>ei(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function El(e){return new Sl({type:"optional",innerType:e})}const Cl=d("ZodNullable",(e,t)=>{ja.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>bc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function di(e){return new Cl({type:"nullable",innerType:e})}const Bl=d("ZodDefault",(e,t)=>{Va.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>yc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType,e.removeDefault=e.unwrap});function _l(e,t){return new Bl({type:"default",innerType:e,get defaultValue(){return typeof t=="function"?t():wn(t)}})}const Dl=d("ZodPrefault",(e,t)=>{Xa.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>kc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function Nl(e,t){return new Dl({type:"prefault",innerType:e,get defaultValue(){return typeof t=="function"?t():wn(t)}})}const ui=d("ZodNonOptional",(e,t)=>{$a.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>vc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function Fl(e,t){return new ui({type:"nonoptional",innerType:e,...k(t)})}const Zl=d("ZodCatch",(e,t)=>{es.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Ic(e,n,i,r),e.unwrap=()=>e._zod.def.innerType,e.removeCatch=e.unwrap});function Rl(e,t){return new Zl({type:"catch",innerType:e,catchValue:typeof t=="function"?t:()=>t})}const Ql=d("ZodPipe",(e,t)=>{ts.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>xc(e,n,i,r),e.in=t.in,e.out=t.out});function hi(e,t){return new Ql({type:"pipe",in:e,out:t})}const Ol=d("ZodReadonly",(e,t)=>{ns.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Sc(e,n,i,r),e.unwrap=()=>e._zod.def.innerType});function Ul(e){return new Ol({type:"readonly",innerType:e})}const Wl=d("ZodLazy",(e,t)=>{is.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>Ec(e,n,i,r),e.unwrap=()=>e._zod.def.getter()});function fi(e){return new Wl({type:"lazy",getter:e})}const zl=d("ZodCustom",(e,t)=>{rs.init(e,t),N.init(e,t),e._zod.processJSONSchema=(n,i,r)=>uc(e,n)});function Tl(e,t={}){return Xs(zl,e,t)}function Kl(e,t){return $s(e,t)}const Gl=64-"Continue: ".length,xt=o().trim().min(1).max(64),Ml=h({task:xt.optional(),title:o().min(1).max(Gl).optional(),goal:o().min(1).max(1e3).optional(),why:o().min(1).max(4e3).optional(),project:xt.optional(),blockedBy:w(xt).max(10).optional()});w(Ml).max(10);const Jl=h({title:o().min(1).max(500),goal:o().max(4e3).optional(),key:o().max(64).optional(),waitsFor:w(o().max(64)).max(10).optional()}),St=w(Jl).max(10),Yl=h({icon:p("minus"),label:o(),restWords:o(),operation:g(["aside","read","hide"]).optional()}),Ll=h({label:o(),restWords:o(),closesTask:S()}),Ce=["fm","inf"],$e="inf";function Pl(e){return[$e,...Ce.filter(t=>t!==$e)].map(t=>`data-${t}-${e}`)}const Et=h({id:o().min(1).max(64).regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),sharedId:o().min(1).max(64).optional(),target:o().min(1).max(200),title:o().min(1).max(200),consequence:o().min(1).max(500),instructions:w(o().min(1).max(2e3)).min(1).max(20),criterion:o().min(1).max(1e3),prerequisites:w(o().min(1).max(64)).max(50),completion:R("kind",[h({kind:p("manual"),label:o().min(1).max(64)}),h({kind:p("device-version"),deviceId:o().min(1).max(64),minVersion:o().regex(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/)})])}),Ct=w(Et).max(20),pi=Et.pick({title:!0,consequence:!0,instructions:!0,criterion:!0}).partial(),Hl=h({operationId:o().min(1).max(128),actor:g(["crewmate","firstmate"]),taskId:o().optional(),label:o().min(1).max(160),at:u(),reason:o().min(1).max(500),generation:u().int().positive(),previous:pi});h({action:o().min(1).max(128),source:o().min(1).max(64),actionId:o().min(1).max(64),expectedGeneration:u().int().positive(),patch:pi,reason:o().min(1).max(500),operationId:o().min(1).max(128),sameAction:S()}),h({requirements:w(h({source:o(),offer:o(),head:o().optional(),action:Et,corrections:w(Hl).optional()})),generation:u().int().positive(),state:g(["blocked","ready","deferred","confirmed","checked","cancelled"]),cardId:o(),presentedGeneration:u().int().nonnegative(),activatedAt:u(),completedAt:u().optional(),cancelledReason:o().optional()}),h({cardId:o(),state:g(["blocked","ready","deferred","confirmed","checked","cancelled"]),result:o()});const ql=g(["quick","standard","reviewed"]);g(["pass","findings","blocked"]),g(["low","medium","high"]);const jl=g(["error","warning","info"]),Vl=g(["auto-fix","ask-user","no-op"]);h({id:o().trim().min(1).max(64),severity:jl,file:o().trim().min(1).optional(),line:u().int().min(1).optional(),text:o().trim().min(1).max(4e3),action:Vl});const mi=h({kind:p("settle"),mode:p("discard"),confirm:p(!0).optional(),proceedWithOpen:p(!0).optional()}),gi=h({kind:p("merge"),review:o().min(1).max(64).optional(),after:g(["close","continue"]),asksFirst:o().min(1).max(400).optional(),proceedWithOpen:p(!0).optional()}),wi=h({kind:p("request_write"),ask:o().min(1).max(64),integration:g(["always","task","once","deny"]).optional()}),bi=g(["link","command","user-command"]),vi=h({deviceId:o().min(1).max(64),providerId:o().min(1).max(256)}),yi=h({deviceId:o().min(1).max(64),host:o().min(1).max(253)}),ki=h({kind:p("open"),target:g(["settings","subscriptions","projects","devices","browser"]),savedSignIn:p(!0).optional(),signIn:o().min(1).max(253).optional(),make:bi.optional(),remove:o().min(1).max(64).optional(),add:o().min(1).max(255).optional(),update:o().min(1).max(64).optional(),signInOn:vi.optional(),forgeSignInOn:yi.optional()}),Xl=["restore-account","move-flagship","retry-firstmate","try-again","add-plugin","decline-plugin","apply-project-change","decline-project-change","plan-queue","keep-delivery","add-project","decline-project","continue-task","move-task","stop-task","start-task","ask-again","confirm-required-action","defer-required-action"];g(["answer-done","dismiss-question","start-task","start-again","stop-task","continue-task","drop-task","queue-task","unqueue-task","show-card"]),h({parts:w(o().min(1).max(64)).max(64),waiting:w(o().min(1).max(64)).max(64),underway:w(o().min(1).max(64)).max(64)}),b({panel:o().min(1).max(40)});const $l=h({kind:p("host"),op:g(Xl),arg:o().optional()}),Ii=R("kind",[mi,gi,wi,ki,$l]);R("kind",[mi,gi,wi,ki]);const Bt=g(["crewmate","firstmate","host"]),eA=/<!--[\s\S]*?(?:-->|$)|<(script|style)(?=[\s>/])[^>]*>(?:[\s\S]*?<\/\1\s*>|[\s\S]*$)|<(\/?)(figure|canvas)(?=[\s>/])[^>]*>/gi;function tA(e){let t=0;for(const[,n,i,r]of e.matchAll(eA)){const s=(n??r??"").toLowerCase();if(s==="style"||s==="canvas"&&!i||s==="script"&&t===0)return!0;s==="figure"&&(t=i?Math.max(0,t-1):t+1)}return!1}const _t=h({id:o(),label:o(),variant:g(["primary","secondary","ghost","danger"]).optional(),default:S().optional(),keepsOpen:S().optional(),effect:Ii.optional(),danger:S().optional(),care:ql.optional(),passes:p("checks").optional()}),nA=b({id:o(),kind:g(["mp4","gif"]),width:u().int().positive(),height:u().int().positive(),durationMs:u().int().positive(),bytes:u().int().positive(),sha256:o().regex(/^[0-9a-f]{64}$/)}),xi=b({sha256:o().regex(/^[0-9a-f]{64}$/).optional(),id:o(),alt:o(),width:u().int().positive(),height:u().int().positive(),group:u().int().nonnegative(),demo:nA.optional()}),Si=32,Ei=R("kind",[b({kind:p("browser"),label:o().min(1).max(Si),taskId:o().min(1).max(64),session:o().min(1).max(64),generation:u().int().positive(),handoff:p(!0).optional()}),b({kind:p("page"),label:o().min(1).max(Si),taskId:o().min(1).max(64),path:o().min(1).max(256)})]),fe=b({level:g(["low","medium","high"]),why:o().min(1).max(100)}),iA=b({blast:fe,behavior:fe,undo:fe,evidence:fe,sensitivity:fe,novelty:fe,deps:fe}),Dt=h({declared:iA});function rA(e){return e.reviewTaskId||e.actions.some(t=>mA(t)||gA(t))?!0:e.risk!==void 0&&e.actions.length===0}function oA(e){const t=Math.max(...Ce.map(r=>e.lastIndexOf(`<div class="${r}-facts" data-facts>`)));if(t<0)return;const n=e.indexOf("</div>",t);if(n<0)return;const i=n+6;return{body:e.slice(0,t)+e.slice(i),facts:e.slice(t,i),at:t}}const Nt=g(["regular","wide","full"]),Ci=g(["answer","close-out"]),aA=b({at:u(),added:u().int().nonnegative(),removed:u().int().nonnegative(),rewritten:S(),marks:w(u().int().nonnegative()).max(512)});g(["chrome","frame"]);const et=256,Ft=256,Bi=200,Zt=16384;`${(64*1024).toLocaleString("en-US")}`;const _i=500,Di=b({name:o().min(1).max(Bi),values:w(o().max(Zt)).max(Ft),labels:w(o().max(Zt)).max(Ft).optional(),changed:S(),json:p(!0).optional(),written:o().min(1).max(4e3).optional()}),Be=w(Di).max(et);b({answers:Be});const Rt=500,sA=64*1024,cA=["single","multiple","text","opaque"],Ni=["no-prompt","conflicting-prompt","label-truncated","duplicate-values","mixed-controls","opaque"],lA=b({value:o().max(Zt),label:o().max(Rt).nullable(),authoredDefault:S(),disabled:S(),hidden:S()}),AA=b({name:o().min(1).max(Bi),kind:g(cA),control:g(["radio","checkbox","select","select-multiple","text","textarea","hidden","staged","mixed"]),prompt:o().max(Rt).nullable(),promptBasis:g(["legend","labelledby","aria-label","label"]).nullable(),options:w(lA).max(Ft),defaultBasis:g(["authored","implicit-first","none"]),required:S(),gaps:w(g(Ni)).max(Ni.length),complete:S(),writeIn:p(!0).optional()}),Qt=w(AA).max(et),Fi=g(["no-fresh-reading","too-large","invalid"]);b({id:o().min(8).max(64),lifecycleId:o().max(64).optional(),offerId:o().max(64).optional(),reading:g(["fresh","fallback","none"]).optional(),remounted:p(!0).optional(),questions:Qt.optional(),questionsGap:Fi.optional()});const dA=["asked","said","chose","automation","from"],uA=b({at:u(),text:o(),kind:g(dA).optional(),choice:o().optional(),card:o().optional(),key:o().optional(),through:u().int().positive().optional()});b({id:o(),taskId:o().optional(),reviewTaskId:o().optional(),author:Bt,priority:u(),title:o(),meta:o(),model:o().optional(),place:o().optional(),body:o(),corner:Yl.optional(),answerDone:h({taskId:o(),label:o(),restWords:o()}).optional(),noteDone:Ll.optional(),requiredActions:Ct.optional(),afterMerge:St.optional(),actions:w(_t),status:g(["streaming","ready"]),createdAt:u(),pictures:w(xi).optional(),width:Nt.optional(),attachment:Ei.optional(),risk:Dt.optional(),replies:p(!1).optional(),answeredBy:p("firstmate").optional(),holdsPlace:p(!0).optional(),asking:p(!0).optional(),designOnly:p(!0).optional(),continues:p(!0).optional(),answering:p(!0).optional(),awaiting:Ci.optional(),minimized:p(!0).optional(),sentBackAt:u().int().nonnegative().optional(),lifecycleId:o().max(64).optional(),offerId:o().max(64).optional(),changes:aA.optional(),asked:uA.optional(),seen:S().optional(),currentUpdateId:o().max(64).optional(),currentUpdateSeen:S().optional()});const Zi=g(["captain","crewmate","firstmate","host"]),tt=512,Ri=b({id:u().int().nonnegative().max(tt+1),label:o().max(160),region:g(["body","title","buttons","whole","preview"]),start:u().int().nonnegative().optional()}),hA=b({lifecycleId:o().min(1).max(64),offerId:o().min(1).max(64),previousOfferId:o().min(1).max(64),released:S(),targets:w(Ri).max(tt+2),removed:u().int().nonnegative()}),fA=b({offerId:o().min(1).max(64),targets:w(Ri).max(tt+2)}),Qi=b({actor:g(["crewmate","firstmate"]),taskId:o().min(1).max(64).optional(),label:o().min(1).max(160)});h({effect:g(["created","revised","reply-only","unchanged","refused"]),cardId:o(),title:o().optional(),lifecycleId:o().optional(),revision:o().optional(),generation:u().int().optional(),contributor:Qi,replyId:u().int().optional(),answered:u().int().optional(),alreadyAnswered:h({messageId:u().int(),by:o(),text:o()}).optional(),clarification:p(!0).optional(),unchanged:w(o()).optional(),display:g(["available","held"]),responseId:o().optional(),refusal:o().optional(),repeated:p(!0).optional()});const Oi=b({revision:hA.optional(),revisionShown:fA.optional(),contributor:Qi.optional(),answersMessage:u().int().positive().optional(),clarification:p(!0).optional(),id:u(),cardId:o(),who:Zi,text:o(),at:u(),answers:Be.optional()});b({cardId:o(),messages:w(Oi)});const pA=["chose","dismissed","author-withdrawal","host-withdrawal","task-retired","duplicate","unknown"];b({id:o(),reviewTaskId:o().optional(),taskId:o().optional(),author:Bt,title:o(),meta:o(),model:o().optional(),body:o(),actions:w(_t.omit({effect:!0})),width:Nt.optional(),requiredActions:Ct.optional(),afterMerge:St.optional(),risk:Dt.optional(),ending:b({how:g(pA),at:u(),actionId:o().optional(),label:o().optional(),by:g(["captain","firstmate","crewmate","host","frame"]).optional()}),answers:Be,messages:w(Oi)}),b({mimeType:g(["image/png","image/jpeg","image/gif","image/webp"]),data:o().min(1).max(75e5),name:o().max(120).optional()});function mA(e){return e.effect?.kind==="settle"?e.effect:void 0}function gA(e){const t=e.effect;if(t?.kind==="merge")return t;if(t?.kind==="settle"&&t.mode==="merge")return{kind:"merge",after:"close",...t.proceedWithOpen?{proceedWithOpen:!0}:{}};if(t?.kind==="request_merge"&&typeof t.review=="string")return{kind:"merge",review:t.review,after:"continue"}}h({kind:p("open"),target:g(["settings","subscriptions","projects","devices","browser"]),browser:h({taskId:o(),session:o(),generation:u().int().positive(),cardId:o()}).optional(),restoreAccountId:o().optional(),signIn:o().optional(),make:bi.optional(),remove:o().optional(),add:o().optional(),update:o().optional(),signInOn:vi.optional(),forgeSignInOn:yi.optional()});const Ot=b({fidelity:g(["matched","mismatched","legacy-missing","unavailable"]),reportedOfferId:o().max(64).optional(),reportedLifecycleId:o().max(64).optional()}),wA=b({at:u(),taskId:o(),key:o(),kind:o(),status:o(),activity:o().nullable(),parentId:o().nullable(),gate:b({kind:o(),ref:o().optional()}).nullable(),delivery:b({mode:o(),changeLabel:o().optional(),headSha:o().optional(),checks:o().optional(),checksAt:u().optional(),review:o().optional(),reviewSha:o().optional(),reviewedAt:u().optional(),settlePending:S()}).nullable(),blockers:w(b({id:o(),status:o()})),asks:w(o())}),Ui=500;b({reviewTaskId:o().optional(),basis:g(["emitted","put","legacy-initial-snapshot"]),fingerprint:o(),author:Bt,title:o(),meta:o(),model:o().optional(),place:o().optional(),body:o(),requiredActions:Ct.optional(),afterMerge:St.optional(),actions:w(_t),pictures:w(xi).optional(),width:Nt.optional(),attachment:Ei.optional(),risk:Dt.optional(),asking:p(!0).optional(),designOnly:p(!0).optional(),continues:p(!0).optional(),answering:p(!0).optional(),holdsPlace:p(!0).optional()}),b({state:g(["available","waiting"]),waitingOn:Ci.optional(),cause:g(["emit","revise","put","close-out","reply","answered","restore"]),closeOut:g(["report","idle","turn-end","restart"]).optional(),replaces:o().optional(),lifecycle:g(["started","reopened","legacy-initial-snapshot"]).optional(),predecessor:o().optional()}),b({actionId:o(),recognized:S(),label:o().nullable(),closes:S(),keepsOpen:S(),effect:Ii.nullable(),frameValue:o().optional(),answers:Be.optional(),display:Ot,reading:g(["fresh","fallback","none"]).optional(),remounted:p(!0).optional(),questions:Qt.optional(),questionsGap:g(["absent","no-fresh-reading","too-large","invalid"]).optional(),context:wA.optional(),contextGap:g(["no-task","task-missing"]).optional(),interactionSource:g(["shell","host"])}),b({messageId:u().int(),who:Zi,interim:p(!0).optional(),answers:Be.optional(),display:Ot.optional()}),b({reason:g(["dismissed","author-withdrawal","host-withdrawal","task-retired","duplicate"]),note:o().max(Ui).optional(),duplicateOf:o().optional(),display:Ot.optional()}),b({interactionId:o(),outcome:g(["completed","refused","failed","queued"]),note:o().max(Ui).optional()}),b({updateId:o().max(64).optional()});const Ut=200,L=o().min(1).max(64),Wt=o().regex(/^[cf]-[a-z0-9]{6}$/),re=h({state:p("unavailable"),reason:o()}),oe=h({id:o(),kind:g(["concept","finding"]),title:o(),retired:S()}),pe=g(["checked","unchecked","recheck","differing","superseded","retired"]),Wi=h({recheck:S(),differing:S()}),bA=h({scope:L,name:o(),private:S(),concepts:u().int().nonnegative(),findings:u().int().nonnegative(),directions:u().int().nonnegative().optional()});R("state",[h({state:p("ready"),collections:w(bA)}),re]),b({scope:L,focus:Wt.optional(),hops:q([p(1),p(2)]).optional(),query:o().max(Ut).optional()});const vA=h({id:o(),title:o(),aliases:w(o()),findings:u().int().nonnegative(),degree:u().int().nonnegative()}),yA=R("kind",[h({kind:p("claim"),id:o(),from:o(),to:o(),predicate:o(),finding:o(),standing:pe}),h({kind:p("context"),id:o(),from:o(),to:o(),reason:o()})]),zi=h({concepts:u().int().nonnegative(),connections:u().int().nonnegative()});R("state",[h({state:p("ready"),scope:L,focus:o().nullable(),concepts:w(vA),connections:w(yA),shown:zi,total:zi}),re]),b({scope:L,query:o().max(Ut).optional(),page:u().int().min(0).max(1e4).optional()});const kA=h({id:o(),title:o(),aliases:w(o()),explanation:o(),findings:u().int().nonnegative()});R("state",[h({state:p("ready"),scope:L,rows:w(kA),total:u().int().nonnegative(),page:u().int().nonnegative()}),re]);const IA=g(["all","recheck","differing"]);b({scope:L,query:o().max(Ut).optional(),filter:IA.optional(),page:u().int().min(0).max(1e4).optional()});const Ti=h({from:oe,predicate:o(),to:oe}),xA=h({id:o(),statement:o(),basis:g(["observation","inference"]),conditions:o(),about:w(oe),relationship:Ti.nullable(),standing:pe,attention:Wi,sources:u().int().nonnegative(),checks:u().int().nonnegative()});R("state",[h({state:p("ready"),scope:L,rows:w(xA),total:u().int().nonnegative(),page:u().int().nonnegative()}),re]);const zt=h({id:o(),kind:p("direction"),text:o(),scope:L,scopeName:o(),origin:o(),authority:g(["instruction","advice"]),revision:u().int().positive(),updatedAt:u()});R("state",[h({state:p("ready"),scope:L,rows:w(zt),total:u().int().nonnegative(),page:u().int().nonnegative()}),re]),b({id:o().min(1).max(64),page:u().int().min(0).max(1e4).optional()});const SA=zt.extend({retired:S(),createdAt:u(),history:w(h({revision:u().int().positive(),op:g(["publish","revise","retire"]),text:o(),origin:o(),scope:L,evidence:o(),at:u()})),page:u().int().nonnegative(),total:u().int().nonnegative()});R("state",[h({state:p("ready"),direction:SA}),h({state:p("missing")}),re]);const Tt=o().regex(/^(d:)?[a-z0-9][a-z0-9-]{0,63}$/),Ki=o().min(1).max(4e3),Kt=o().min(1).max(400),Gi=u().int().positive().optional();R("op",[b({op:p("add"),id:Tt.optional(),text:Ki,scope:L.optional(),reason:Kt}),b({op:p("revise"),id:Tt,text:Ki,expectedRevision:Gi,reason:Kt}),b({op:p("retire"),id:Tt,expectedRevision:Gi,reason:Kt})]),h({op:g(["add","revise","retire"]),direction:zt}),b({id:Wt,revision:u().int().positive().optional()});const EA=R("kind",[h({kind:p("file"),path:o(),startLine:u().int(),endLine:u().int(),commit:o().nullable(),dirty:S()}),h({kind:p("report"),key:o(),event:u().int()}),h({kind:p("quote"),citation:o()}),h({kind:p("article"),url:o(),title:o(),author:o().nullable(),published:o().nullable(),retrieved:u()})]),Mi=h({id:o(),origin:EA,text:o(),capturedAt:u(),check:h({state:g(["unchanged","changed","missing","unknown","kept"]),detail:o()})}),CA=h({id:o(),revision:u().int().positive(),verdict:g(["supports","contradicts","inconclusive"]),method:o(),conditions:o(),by:o(),at:u(),sources:w(Mi)}),BA=h({revision:u().int().positive(),op:g(["publish","revise","link","retire","restore"]),by:o(),reason:o(),at:u(),title:o()}),_A=h({type:g(["contradicts","supersedes","duplicates"]),reason:o(),other:oe,outgoing:S(),by:o(),at:u()}),DA=h({revision:u().int().positive(),by:o(),task:o().nullable(),purpose:o(),at:u()}),NA=R("kind",[h({kind:p("claim"),id:o(),finding:o(),from:oe,predicate:o(),to:oe,standing:pe}),h({kind:p("context"),id:o(),from:oe,to:oe,reason:o()})]),FA=h({id:o(),scope:L,kind:g(["concept","finding"]),revision:u().int().positive(),current:u().int().positive(),retired:S(),title:o(),aliases:w(o()),explanation:o(),basis:g(["observation","inference"]).nullable(),conditions:o(),about:w(oe),relationship:Ti.nullable(),standing:pe.nullable(),attention:Wi.nullable(),author:o(),createdAt:u(),at:u(),connections:w(NA),findings:w(h({id:o(),statement:o(),standing:pe})),findingsTotal:u().int().nonnegative(),sources:w(Mi),checks:w(CA),revisions:w(BA),olderRevisions:u().int().nonnegative(),relations:w(_A),uses:h({count:u().int().nonnegative(),recent:w(DA)})});R("state",[h({state:p("ready"),entry:FA}),h({state:p("missing")}),re]);const ZA="(?<![A-Za-z0-9_-])[cf]-[a-z0-9]{6}(?![A-Za-z0-9_-])",RA=/^[cf]-[a-z0-9]{6}$/;b({ids:w(Wt).min(1).max(32)});const QA=h({id:o(),kind:g(["concept","finding"]),scope:L,title:o(),revision:u().int().positive(),retired:S(),standing:pe.nullable()});R("state",[h({state:p("ready"),refs:w(QA)}),re]),b({task:o().min(1).max(64)});const OA=h({id:o(),kind:g(["concept","finding"]),scope:L,revision:u().int().positive(),title:o(),current:u().int().positive(),currentTitle:o(),retired:S(),standing:pe.nullable(),purpose:o(),at:u()});R("state",[h({state:p("ready"),uses:w(OA),total:u().int().nonnegative()}),re]);const Ji="(?<![A-Za-z0-9_-])[A-Z0-9]{2,4}-[0-9]{1,9}(?![A-Za-z0-9_-])",UA=/^[A-Z0-9]{2,4}-[0-9]{1,9}$/,WA=64;function zA(e){const t=[];for(const n of e.matchAll(new RegExp(Ji,"g")))if(!t.includes(n[0])&&(t.push(n[0]),t.length===WA))break;return t}const TA=["GET","HEAD","POST","PUT","PATCH","DELETE"],KA={responseMaxBytes:1048576},GA=/^[A-Za-z0-9-]{1,64}$/,MA=["authorization","cookie","host","origin","proxy-authorization","referer","user-agent"],Yi=b({method:g(TA).default("GET"),path:o().min(1).max(2048).regex(/^\/(?![/\\])/,"an absolute path"),query:V(o().min(1).max(256),o().max(2048)).optional(),headers:V(o().regex(GA),o().max(4096)).optional().refine(e=>!e||Object.keys(e).every(t=>!MA.includes(t.toLowerCase())),"a reserved header"),body:o().max(65536).optional()}),JA=["capability_not_granted","method_not_granted","timeout","network","oversized","rate_limited"];R("ok",[h({ok:p(!0),status:u().int().min(100).max(599),headers:V(o(),o()),body:o().max(KA.responseMaxBytes)}),h({ok:p(!1),error:h({code:g(JA),message:o().max(500)})})]),b({pluginId:o().min(2).max(64),alias:o().min(1).max(32),request:Yi});const Li=2,YA=4096,LA=1024,PA=16*1024*1024,HA=4096,qA="app-frame://media/",jA=256,Pi=4096,VA=500,XA=6,_e=u().int().positive().max(Number.MAX_SAFE_INTEGER),G=p(Li),$A=["get","set","delete","list"],Hi=128,ed=R("verb",[h({verb:p("subscribe"),sub:_e,read:o().min(1).max(64),args:V(o(),j()).default({})}),h({verb:p("unsubscribe"),sub:_e}),h({verb:p("action"),action:o().min(1).max(200),value:j().optional()}),h({verb:p("fetch"),alias:o().min(1).max(32),request:Yi}),h({verb:p("store"),op:g($A),key:o().min(1).max(Hi).optional(),value:j().optional(),prefix:o().max(Hi).optional()})]),qi=h({src:o().min(1).max(PA),alt:o().max(HA),width:u().int().nonnegative(),height:u().int().nonnegative()}),nt=u().int().nonnegative().max(et),td=Di.extend({written:o().min(1).max(_i).optional()}),nd=h({answered:nt,of:nt,changed:nt,picked:nt,answers:w(td).max(et)}),id=["rest","leave","open"],rd=h({top:u().finite(),right:u().finite(),bottom:u().finite(),left:u().finite()}),od=R("type",[h({fm:G,type:p("revealed"),document:o(),seq:_e,offerId:o().min(1).max(64),top:u().finite().nonnegative().max(1e6).optional(),height:u().finite().nonnegative().max(1e6).optional()}),h({fm:G,type:p("ready"),document:o().optional(),reuseReads:S().optional()}),h({fm:G,type:p("request"),id:_e}).loose(),h({fm:G,type:p("resize"),height:u().finite().nonnegative(),document:o().optional(),width:u().finite().nonnegative().optional(),initialized:S().optional(),live:S().optional(),held:S().optional()}),h({fm:G,type:p("link"),href:o().min(1).max(2048)}),h({fm:G,type:p("draft"),document:o(),text:o().min(1).max(VA).regex(/^[^\r\n]*$/)}),h({fm:G,type:p("image"),index:u().int().nonnegative(),pictures:w(qi).min(1).max(LA)}),h({fm:G,type:p("demo"),src:o().min(1).max(jA),poster:qi,caption:o().max(Pi),durationMs:u().int().nonnegative(),play:S()}),h({fm:G,type:p("interaction"),document:o()}),h({fm:G,type:p("focused"),document:o(),focused:S()}),h({fm:G,type:p("pressed"),document:o()}),h({fm:G,type:p("escape"),document:o()}),h({fm:G,type:p("task"),document:o(),gesture:g(id),key:o().regex(UA),box:rd.optional()}),h({fm:G,type:p("entry"),document:o(),id:o().regex(RA)}),h({fm:G,type:p("pong"),seq:_e}),nd.extend({fm:G,type:p("answers"),seq:_e.optional(),questions:j().optional(),questionsGap:Fi.optional()})]),ad=`(function () {
  var VERSION = ${Li};
  var LABEL_MAX = ${Rt};
  var QUESTIONS_MAX_BYTES = ${sA};
  var WRITTEN_MAX = ${_i};
  var nextId = 1;
  var pending = {};
  var subscriptions = {};
  var receiveReadValue = function (previous, message) {
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
};
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
  var KEY_IN_TEXT = new RegExp(${JSON.stringify(`${Ji}|${ZA}`)}, "g");
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
  var OTHERS = ${JSON.stringify(Ce.filter(e=>e!==$e))};
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
  ${Ce.map(e=>`window.${e} = fm;`).join(" ")}
  ${Ce.map(e=>`window.${e}Action = function (id) { fm.action(id).catch(function () {}); };`).join(" ")}
  var STRIP_SHOWN = ${XA};
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
  var DEMO_SOURCE = ${JSON.stringify(qA)};
  var DEMO_CAPTION_MAX = ${Pi};
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
})();`,sd="sha256-kyKGhteYf8iScLYERPNPWiHDGk1PY0lZ90Dcw46ddKg=",ae="app-frame",ji="images",Vi="media",cd={mp4:"video/mp4",gif:"image/gif"},ld={png:"image/png",jpg:"image/jpeg",webp:"image/webp"},Ad=/^([A-Za-z0-9_-]{1,64})-([0-9a-f]{32})\.(png|jpg|webp)$/,dd=/^([A-Za-z0-9_-]{1,64})-([0-9a-f]{32})\.(mp4|gif)$/;function Xi(e){const t=Ad.exec(e);if(!t)return;const[,n,,i]=t;if(!(!n||!i))return{taskId:n,fileName:e,contentType:ld[i]}}function $i(e){const t=dd.exec(e);if(!t)return;const[,n,,i]=t;if(!n||!i)return;const r=i;return{taskId:n,fileName:e,kind:r,contentType:cd[r]}}function ud(e){const t=`${ae}://${Vi}/`;return e.startsWith(t)?$i(e.slice(t.length))?.kind:void 0}const hd=new RegExp(`data-(?:${Ce.join("|")})-demo="([^"]*)"`,"g");function fd(e){return ud(e)!==void 0}function pd(e){const t=new Set;for(const n of e.matchAll(hd)){const i=n[1]??"";fd(i)&&t.add(i)}return t}const md=/^data:image\/(png|jpeg|gif|webp)[;,]/;function er(e){if(md.test(e))return!0;const t=`${ae}://${ji}/`;return e.startsWith(t)&&Xi(e.slice(t.length))!==void 0}function tr(e,t){const n=t[e];if(!n||!er(n.src))return;const i=t.filter(r=>er(r.src));return{index:i.indexOf(n),pictures:i}}const gd=["allow-scripts"].join(" "),wd=`${ae}:`,bd=`${ae}://fonts`,vd=`data: ${ae}:`;function Gt(e=[],t=wd){const n=[sd,...e].map(i=>`'${i}'`).join(" ");return`default-src 'none'; style-src 'unsafe-inline'; font-src ${t}; img-src ${vd}; script-src ${n}`}Gt(),Gt([],bd);const nr=["v_version_v1","v_tasks_v1","v_task_events_v1","v_usage_v1","v_feed_v1","v_quota_windows_v1","v_routing_v1","v_placements_v1","v_projects_v1","v_repos_v1"],yd=/^v_[a-z][a-z0-9_]*_v[1-9][0-9]*$/,We=o().regex(yd,{message:"a versioned view name, such as v_usage_v1"}),it={textBytes:4096,params:32,paramBytes:4096};function ir(e){return new TextEncoder().encode(e).byteLength}const rr=q([o().refine(e=>ir(e)<=it.paramBytes,"a param is at most 4 KB"),u().finite(),Xe()]),or=o().min(1).refine(e=>ir(e)<=it.textBytes,"a query is at most 4 KB");b({sql:or,params:w(rr).max(it.params).optional()}),b({sql:or,params:w(rr).max(it.params).optional(),views:w(We).max(64)});const kd=["sql_view_not_declared","sql_not_readonly","sql_invalid","sql_timeout","sql_too_large"],Id=q([o(),u(),Xe()]),xd=h({columns:w(o()),rows:w(V(o(),Id)),truncated:S(),elapsedMs:u()}),Sd=h({refused:g(kd),message:o()});q([Sd,xd]);const rt={"commands.search":{label:"Search commands",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"k",meta:!0}]},"focus.main-message":{label:"Go to the main message",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"l",meta:!0}]},"focus.card-reply":{label:"Go to the card's reply",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"l",meta:!0,shift:!0}],searchWords:["anything to add","comment"]},"focus.card-body":{label:"Go to the card's body",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"focus.card-actions":{label:"Go to the card's buttons",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"cards.choice-1":{label:"Press the recommended choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"1",meta:!0}],searchWords:["card","button","default","first"]},"cards.choice-2":{label:"Press the second choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"2",meta:!0}],searchWords:["card","button"]},"cards.choice-3":{label:"Press the third choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"3",meta:!0}],searchWords:["card","button"]},"cards.choice-4":{label:"Press the fourth choice",scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[{key:"4",meta:!0}],searchWords:["card","button"]},"regions.next":{label:"Go to the next part of the window",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"F6"}]},"regions.previous":{label:"Go to the previous part of the window",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"F6",shift:!0}]},"computers.previous":{label:"Previous work computers",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"computers.next":{label:"Next work computers",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"project-focus.open":{label:"Focus on a project",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[{key:"p",meta:!0,shift:!0}],searchWords:["filter","project","pill"]},"project-focus.clear":{label:"Show all projects",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["filter","focus","project","clear"]},"cards.previous":{label:"Show the previous card",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"[",meta:!0,shift:!0},{key:"{",meta:!0,shift:!0}]},"cards.next":{label:"Show the next card",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"]",meta:!0,shift:!0},{key:"}",meta:!0,shift:!0}]},"cards.minimize":{label:"Put card aside",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[{key:"m",meta:!0,shift:!0}]},"cards.done":{label:"Press the note's Done or Got it",searchWords:["card","note","answer","done","got it"],scope:"window",runs:"shell",repeat:!1,risk:"close",keys:[]},"cards.maximize":{label:"Maximize or restore card",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["full","screen","enlarge","expand","bigger"]},"cards.next-revision":{label:"Go to the next revised area",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["changes","revision","links"]},"cards.thread":{label:"Show or hide the card's thread",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:"\\",meta:!0}],searchWords:["collapse","expand","chat","replies","messages"]},"cards.show-info":{label:"Show Info",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","record","tab","open"]},"cards.show-cards":{label:"Show Cards",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","record","tab","decisions","notes"]},"cards.show-activity":{label:"Show Activity",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","record","tab","timeline","history"]},"cards.show-crewmate":{label:"Show Crewmate",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","session","transcript","tab"]},"browser.control":{label:"Take or return browser control",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["handback","take","return","browser"]},"task.move-computer":{label:"Move the task to another computer",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["computer","mac","machine","move","device","record"]},"cards.show-browser":{label:"Show Browser",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","page","tab"]},"cards.next-tab":{label:"Next tab",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","tab"]},"cards.previous-tab":{label:"Previous tab",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["task","tab"]},"settings.open":{label:"Open Settings",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[{key:",",meta:!0}]},"settings.keyboard":{label:"Open Keyboard settings",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[]},"settings.panels":{label:"Arrange panels",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["rails","layout","order","move","hide","show"]},"updates.show":{label:"Show available update",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["update","restart","stable","alpha"]},"updates.later":{label:"Update later",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["update","later","cancel","saving","work"]},"updates.check":{label:"Check for updates",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["update","version","release","new"]},"whats-new.show":{label:"Show what's new",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["release","notes","changes","version"]},"firstmate.reply":{label:"Open the first mate's reply",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["answer","message","note","last"]},"settings.runbooks":{label:"Open Runbooks",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["guidance","skills","instructions"]},"runbooks.open-folder":{label:"Open your runbooks folder",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["directory","guidance","customize"]},"settings.usage":{label:"Open Usage",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["tokens","models","cost","dollars"]},"settings.automation":{label:"Open Automation",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["schedule","scheduled","recurring","reminder","pause"]},"settings.integrations":{label:"Open Integrations",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["github","connection","connect","sign in"]},"automation.pause-all":{label:"Pause all automations",scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["schedule","scheduled","recurring","stop"]},"usage.unit":{label:"Switch Usage units",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["tokens","cost","dollars","estimate"]},"allowance.recheck":{label:"Recheck allowance",scope:"window",runs:"shell",repeat:!1,risk:"view",keys:[],searchWords:["quota","refresh","usage","limit","account","switch"]},"devices.try-again":{label:`Try again to reach your ${{many:"computers"}.many}`,scope:"window",runs:"shell",repeat:!1,risk:"navigate",keys:[],searchWords:["devices","ssh","reconnect","connect","macs"],section:"devices"},"size.larger":{label:"Make everything larger",scope:"window",runs:"main",repeat:!0,risk:"view",keys:[{key:"+",meta:!0},{key:"=",meta:!0},{key:"+",ctrl:!0},{key:"=",ctrl:!0}]},"size.smaller":{label:"Make everything smaller",scope:"window",runs:"main",repeat:!0,risk:"view",keys:[{key:"-",meta:!0},{key:"-",ctrl:!0}]},"size.reset":{label:"Return to the usual size",scope:"window",runs:"main",repeat:!0,risk:"view",keys:[{key:"0",meta:!0},{key:"0",ctrl:!0}]},"message.delete-to-line-start":{label:"Delete back to the start of the line",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"u",ctrl:!0}]},"message.delete-to-line-end":{label:"Delete to the end of the line",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"k",ctrl:!0}]},"message.delete-word-before":{label:"Delete the word before the cursor",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"w",ctrl:!0}]},"message.put-back-deleted":{label:"Put back what was last deleted",scope:"message-field",repeat:!0,risk:"edit",keys:[{key:"y",ctrl:!0}]},"message.recall":{label:"Bring back the last message sent",scope:"main-message",repeat:!1,risk:"edit",keys:[{key:"ArrowUp"},{key:"p",ctrl:!0}]}};function Ed(e){return rt[e].scope==="window"}function ar(e){return rt[e].runs==="shell"}const Mt=Object.keys(rt);Mt.filter(ar),Mt.filter(e=>Ed(e)&&!ar(e));function sr(e,t){return t==="mac"||!e.meta&&!e.ctrl?e:e.ctrl?null:{key:e.key,ctrl:!0,...e.alt?{alt:!0}:{},...e.shift?{shift:!0}:{}}}function Cd(e,t){if(t==="mac")return e;const n=[];for(const i of e){const r=sr(i,t),s=i.second?sr(i.second,t):void 0;if(!r||s===null)continue;const a=s?{...r,second:s}:r;n.some(c=>JSON.stringify(c)===JSON.stringify(a))||n.push(a)}return n}function Bd(e,t="mac"){return Cd(rt[e].keys,t)}function _d(e){return Object.fromEntries(Mt.map(t=>[t,Bd(t,e)]))}_d("mac");const cr=g(["regular","wide","full"]),lr=g(["content","fill"]),Dd=g(["open","search","add","list","note","filter","clock","chart"]),Nd=3,Fd=16,ot=16,Ar=3072,dr=4096,De=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/,de=o().min(1).max(32).regex(De,"kebab-case"),Zd=/^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$/,ur=o().regex(Zd,"a plain id"),hr=o().min(1).max(80),at=fi(()=>q([Xe(),S(),u().finite(),o(),w(at),V(o(),at)])),st=at.refine(e=>JSON.stringify(e).length<=Ar,`a card's data is at most ${Ar} bytes of JSON`);at.refine(e=>new TextEncoder().encode(JSON.stringify(e)).byteLength<=dr,`a card keeps at most ${dr} bytes of JSON`);const Rd=b({view:de,title:hr,width:cr.optional(),height:lr.optional(),data:st.optional()}),Qd=b({id:de,icon:Dd,label:o().min(1).max(40),emits:de.optional(),data:st.optional()}),Od=b({id:de,label:o().min(1).max(60),emits:de.optional(),presses:de.optional(),data:st.optional(),key:o().min(1).max(12).refine(e=>Wd(e)!==null,"a key as a Mac writes it, such as ⌘B").optional(),words:w(o().min(1).max(24).regex(/^\S+$/,"one word")).max(8).optional()}).refine(e=>e.emits===void 0!=(e.presses===void 0),"a command either emits a card or presses a header button");b({id:ur.optional(),view:de,title:hr,width:cr.optional(),height:lr.optional(),data:st.optional()});const Jt=V(de,Rd).refine(e=>Object.keys(e).length<=ot,`at most ${ot} named cards`),Yt=w(Qd).max(Nd),Lt=w(Od).max(Fd),Ud={"⌃":"ctrl","⌥":"alt","⇧":"shift","⌘":"meta"};function Wd(e){const t={key:""};let n=e;for(;n.length>0;){const i=Ud[n[0]];if(!i)break;if(t[i])return null;t[i]=!0,n=n.slice(1)}return/^F([1-9]|1[0-9]|2[0-4])$/.test(n)?{...t,key:n}:[...n].length!==1||/\s/.test(n)?null:{...t,key:/^[A-Za-z]$/.test(n)?n.toLowerCase():n}}const fr=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/,zd=o().min(2).max(64).regex(fr,"kebab-case id"),Pt=o().min(1).max(64).regex(fr,"kebab-case id"),Td=/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/,Kd=g(["decision","note","attention","record"]),Gd=b({kind:Pt,chrome:Kd,body:b({streaming:g(["plain","html"])})}),Md=b({id:Pt,label:o().min(1).max(24),order:u().int().min(0).max(1e3),width:g(["standard","wide"]).default("wide")}),Jd=g(["left","right"]),Yd=g(["top","bottom"]),Ld=b({x:Jd,y:Yd}),Pd=g(["content","fill"]),Hd=b({id:Pt,title:o().min(1).max(40),preferredPlacement:Ld,order:u().int().min(0).max(1e3),size:Pd.default("content"),newestLast:S().default(!1),cardViews:w(o().regex(De)).max(ot).optional(),cards:Jt.optional(),header:Yt.optional(),commands:Lt.optional()});function Ht(e,t,n,i){const r=new Set;for(const s of e){const a=t(s);r.has(a)&&n.addIssue({code:"custom",message:`duplicate ${i} id "${a}"`}),r.add(a)}}const qd=b({cardKinds:w(Gd).default([]).superRefine((e,t)=>Ht(e,n=>n.kind,t,"card-kind")),settingsSections:w(Md).default([]).superRefine((e,t)=>Ht(e,n=>n.id,t,"settings-section")),sidePanels:w(Hd).default([]).superRefine((e,t)=>Ht(e,n=>n.id,t,"side-panel"))}),pr=1048576;function ct(e){return`"${e}" is retired: a panel reaches a service outside your projects only through an integration. Name the connection, its actions and why under "integrations".`}const mr=o().min(1).max(64).regex(/^[^\s/][^/]*$/,"a name with no slash"),jd=o().min(1).max(48).regex(/^[^\s/][^/]*$/,"a name with no slash"),Vd=b({integration:mr,actions:w(mr).optional(),events:w(jd).optional(),why:o().trim().min(1)}).superRefine((e,t)=>{!e.actions?.length&&!e.events?.length&&t.addIssue({code:"custom",message:`"${e.integration}" names no action and no event`})}),gr=w(Vd).superRefine((e,t)=>{const n=new Set;for(const i of e){const r=i.integration.trim().toLowerCase();n.has(r)&&t.addIssue({code:"custom",message:`"${i.integration}" is named twice`}),n.add(r)}}),Xd=o().min(1).max(64).regex(/^[a-z][a-z0-9-]*(?:\.[a-z][a-z0-9-]*)*$/,"dotted read-catalog name"),$d=b({net:Ee({message:ct("net")}).optional(),secrets:Ee({message:ct("secrets")}).optional(),integrations:gr.optional(),storage:b({kv:b({maxBytes:u().int().positive().max(pr)})}).optional(),reads:w(Xd).max(64).optional(),sql:w(We).max(nr.length).optional(),moves:p(!0).optional()});b({id:zd,name:o().min(1).max(40),version:o().regex(Td,"semver"),contributes:qd,capabilities:$d});const eu=/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/,ue=o().min(2).max(48).regex(eu),tu=["yours","installed"],qt=128,ze=["computers.resources","quota.snapshot","tasks.board","tasks.detail","tasks.search","feed.recent","forge.changes","automation.list","knowledge.collections","knowledge.graph","knowledge.concepts","knowledge.directions","knowledge.findings","knowledge.entry","knowledge.direction"],wr=g(ze),Te=fi(()=>q([Xe(),S(),u().finite(),o(),w(Te),V(o(),Te)])),nu=h({key:o(),value:Te,updatedAt:u()}),iu=q([b({always:p(!0)}),b({store:o().min(1).max(qt),when:p("nonEmpty")}),b({code:p(!0)})]),br=b({x:g(["left","right"]),y:g(["top","bottom"])});b({api:q([p(1),p(2)],{message:"this panel is written for a version of the panel API this app does not serve"}).optional(),name:o().min(1).max(40).optional(),version:o().regex(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/,"semver").optional(),title:o().min(1).max(40).optional(),placement:br.optional(),order:u().int().min(0).max(1e3).optional(),size:g(["content","fill"]).optional(),newestLast:S().optional(),presence:iu.optional(),cards:Jt.optional(),header:Yt.optional(),commands:Lt.optional(),reads:w(wr).max(ze.length).optional(),moves:p(!0).optional(),sql:w(We).max(64).optional(),integrations:gr.optional(),net:Ee({message:ct("net")}).optional(),secrets:Ee({message:ct("secrets")}).optional(),storage:b({kv:b({maxBytes:u().int().positive().max(pr)})}).optional(),origin:b({taskId:o().min(1).max(64).optional()}).optional()}),new Set(ze),new Set(nr);const ru=h({stage:g(["manifest","panel","server"]),message:o()}),vr=h({id:ue,source:g(tu),by:o().min(1).max(40).nullable(),title:o().min(1).max(40),placement:br,order:u().int(),size:g(["content","fill"]),newestLast:S().optional(),present:S(),ownPresence:S(),moves:S(),running:S(),reads:w(wr),sql:w(We),panel:h({url:o(),version:o()}).nullable(),frame:h({version:o()}).nullable(),cardViews:w(o().regex(De)).max(ot),cards:Jt,header:Yt,commands:Lt,server:h({actions:w(o()),background:w(h({id:o(),everyMs:u()}))}).nullable(),error:ru.nullable(),stopped:h({reason:g(["unresponsive","exited"]),at:o(),version:o()}).optional(),paused:h({api:u().int().min(1),serves:w(u().int().min(1)),asked:S()}).optional(),integrationAsks:w(h({integration:o().min(1).max(200),place:o().min(1).max(200),action:o().min(1).max(200),label:o().min(1).max(200),state:g(["asking","declined"])})).optional()});h({extensions:w(vr),drafts:w(vr).optional()}),h({extensionId:ue,key:o(),draft:p(!0).optional()});const jt=o().min(1).max(qt),Ke=p(!0).optional();R("op",[h({op:p("get"),extensionId:ue,key:jt,draft:Ke}),h({op:p("set"),extensionId:ue,key:jt,value:Te,draft:Ke}),h({op:p("delete"),extensionId:ue,key:jt,draft:Ke}),h({op:p("list"),extensionId:ue,prefix:o().max(qt).optional(),draft:Ke})]),h({value:Te.optional(),entries:w(nu).optional()}),h({draft:Ke}),R("op",[h({op:p("list")}),h({op:p("show"),name:o().min(1).max(200)}),h({op:p("call"),name:o().min(1).max(200),action:o().min(1).max(200),input:j().optional()})]),q([h({text:o(),refused:g(["refused","invalid"]).optional()}),w(V(o(),j())),V(o(),j())]),q([h({ok:p(!0),result:j()}),h({ok:p(!1),error:o()})]);const ou=["activity","automation","knowledge","now"],lt=524288;function Vt(e){const t=new RegExp(`</${e}`,"i");return n=>!t.test(n)}const au=b({html:o().max(lt).refine(Vt("body"),"a </body> tag"),script:o().min(1).max(lt).refine(Vt("script"),"a <\/script> tag").optional()}),su=b({html:o().max(lt)}),cu=g(["dark","light"]),Xt=b({title:o().min(1).max(120),theme:cu,style:o().max(lt).refine(Vt("style"),"a </style> tag")}),lu=Xt.extend({template:au,kind:fl().optional()}),Au=Xt.extend({template:su,kind:p("card")}),du=R("source",[b({source:p("builtin"),id:g(ou),view:o().regex(De).optional()}),b({source:p("installed"),id:ue,version:o().regex(/^[0-9a-f]{16}$/),view:o().regex(De).optional()}),b({source:p("personal"),id:ue,version:o().regex(/^[0-9a-f]{16}$/),draft:p(!0).optional(),view:o().regex(De).optional()})]),uu=b({id:o().min(1).max(64).regex(/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/),reads:w(g(ze)).max(ze.length),sql:w(We).max(64),card:b({id:ur}).optional(),moves:S().optional(),server:S().optional()}),hu=Xt.extend({kind:p("panel"),panel:du,config:uu});q([Au,hu,lu]),h({mountId:o().min(1).max(64),url:o().startsWith(`${ae}://`)});function fu(e){return`${ae}://fonts/${e}`}function $t(e){return e.replaceAll("&","&amp;").replaceAll('"',"&quot;").replaceAll("<","&lt;")}function pu(e){const t=$t(e.theme);return["<!doctype html>",`<html data-theme="${t}"${e.held?" data-inf-held":""}>`,"<head>",`<meta http-equiv="Content-Security-Policy" content="${$t(e.csp)}">`,'<meta charset="utf-8">',...e.title?[`<title>${$t(e.title)}</title>`]:[],`<style>${e.style}</style>`,`<script>${ad}<\/script>`,"</head>",`<body data-theme="${t}">`,e.html,...e.script?[`<script>${e.script}<\/script>`]:[],"</body>","</html>"].join(`
`)}const mu=/https?:\/\/[^\s<>"'`]+/gi;function en(e,t,n){let i=0;for(const r of e)r===t?i+=1:r===n&&(i-=1);return i<0}function gu(e){let t=e,n="";for(;t.length>0;){const i=t[t.length-1];if(!i||!(/[.,;:!?']/.test(i)||i===")"&&en(t,"(",")")||i==="]"&&en(t,"[","]")||i==="}"&&en(t,"{","}")))break;t=t.slice(0,-1),n=i+n}return{url:t,trailing:n}}function wu(e){try{const t=new URL(e);return t.protocol==="http:"||t.protocol==="https:"}catch{return!1}}function yr(e){try{const t=new URL(e);if(t.protocol==="https:")return!0;if(t.protocol==="http:"){const n=t.hostname.toLowerCase();return n==="localhost"||n.endsWith(".localhost")||n==="127.0.0.1"||n==="::1"||n==="[::1]"}return!1}catch{return!1}}function bu(e){const t=[];let n=0;for(const i of e.matchAll(mu)){const r=i.index??0,{url:s}=gu(i[0]);!s||!wu(s)||(r>n&&t.push({type:"text",value:e.slice(n,r)}),t.push({type:"url",value:s}),n=r+s.length)}return n<e.length&&t.push({type:"text",value:e.slice(n)}),t}const vu=new Map([[0,65533],[128,8364],[130,8218],[131,402],[132,8222],[133,8230],[134,8224],[135,8225],[136,710],[137,8240],[138,352],[139,8249],[140,338],[142,381],[145,8216],[146,8217],[147,8220],[148,8221],[149,8226],[150,8211],[151,8212],[152,732],[153,8482],[154,353],[155,8250],[156,339],[158,382],[159,376]]);function yu(e){return e>=55296&&e<=57343||e>1114111?65533:vu.get(e)??e}function kr(e){const t=atob(e),n=t.length&-2,i=new Uint16Array(n/2);for(let r=0,s=0;r<n;r+=2){const a=t.charCodeAt(r),c=t.charCodeAt(r+1);i[s++]=a|c<<8}return i}const ku=kr("QR08ALkAAgH6AYsDNQR2BO0EPgXZBQEGLAbdBxMISQrvCmQLfQurDKQNLw4fD4YPpA+6D/IPAAAAAAAAAAAAAAAAKhBMEY8TmxUWF2EYLBkxGuAa3RsJHDscWR8YIC8jSCSIJcMl6ie3Ku8rEC0CLjoupS7kLgAIRU1hYmNmZ2xtbm9wcnN0dVQAWgBeAGUAaQBzAHcAfgCBAIQAhwCSAJoAoACsALMAbABpAGcAO4DGAMZAUAA7gCYAJkBjAHUAdABlADuAwQDBQHIiZXZlAAJhAAFpeW0AcgByAGMAO4DCAMJAEGRyAADgNdgE3XIAYQB2AGUAO4DAAMBA8CFoYZFj4SFjcgBhZAAAoFMqAAFncIsAjgBvAG4ABGFmAADgNdg43fAlbHlGdW5jdGlvbgCgYSBpAG4AZwA7gMUAxUAAAWNzpACoAHIAAOA12Jzc6SFnbgCgVCJpAGwAZABlADuAwwDDQG0AbAA7gMQAxEAABGFjZWZvcnN1xQDYANoA7QDxAPYA+QD8AAABY3LJAM8AayNzbGFzaAAAoBYidgHTANUAAKDnKmUAZAAAoAYjeQARZIABY3J0AOAA5QDrAGEidXNlAACgNSLuI291bGxpcwCgLCFhAJJjcgAA4DXYBd1wAGYAAOA12Dnd5SF2ZdhiYwDyAOoAbSJwZXEAAKBOIgAHSE9hY2RlZmhpbG9yc3UXARoBHwE6AVIBVQFiAWQBZgGCAakB6QHtAfIBYwB5ACdkUABZADuAqQCpQIABY3B5ACUBKAE1AfUhdGUGYWmg0iJ0KGFsRGlmZmVyZW50aWFsRAAAoEUhbCJleXMAAKAtIQACYWVpb0EBRAFKAU0B8iFvbgxhZABpAGwAO4DHAMdAcgBjAAhhbiJpbnQAAKAwIm8AdAAKYQABZG5ZAV0BaSJsbGEAuGB0I2VyRG90ALdg8gA5AWkAp2NyImNsZQAAAkRNUFRwAXQBeQF9AW8AdAAAoJkiaSJudXMAAKCWIuwhdXMAoJUiaSJtZXMAAKCXIm8AAAFjc4cBlAFrKndpc2VDb250b3VySW50ZWdyYWwAAKAyImUjQ3VybHkAAAFEUZwBpAFvJXVibGVRdW90ZQAAoB0gdSJvdGUAAKAZIAACbG5wdbABtgHNAdgBbwBuAGWgNyIAoHQqgAFnaXQAvAHBAcUB8iJ1ZW50AKBhIm4AdAAAoC8i7yV1ckludGVncmFsAKAuIgABZnLRAdMBAKACIe8iZHVjdACgECJuLnRlckNsb2Nrd2lzZUNvbnRvdXJJbnRlZ3JhbAAAoDMi7yFzcwCgLypjAHIAAOA12J7ccABDoNMiYQBwAACgTSKABURKU1phY2VmaW9zAAsCEgIVAhgCGwIsAjQCOQI9AnMCfwNvoEUh9CJyYWhkAKARKWMAeQACZGMAeQAFZGMAeQAPZIABZ3JzACECJQIoAuchZXIAoCEgcgAAoKEhaAB2AACg5CoAAWF5MAIzAvIhb24OYRRkbAB0oAciYQCUY3IAAOA12AfdAAFhZkECawIAAWNtRQJnAvIjaXRpY2FsAAJBREdUUAJUAl8CYwJjInV0ZQC0YG8AdAFZAloC2WJiJGxlQWN1dGUA3WJyImF2ZQBgYGkibGRlANxi7yFuZACgxCJmJWVyZW50aWFsRAAAoEYhcAR9AgAAAAAAAIECjgIAABoDZgAA4DXYO91EoagAhQKJAm8AdAAAoNwgcSJ1YWwAAKBQIuIhbGUAA0NETFJVVpkCqAK1Au8C/wIRA28AbgB0AG8AdQByAEkAbgB0AGUAZwByAGEA7ADEAW8AdAKvAgAAAACwAqhgbiNBcnJvdwAAoNMhAAFlb7kC0AJmAHQAgAFBUlQAwQLGAs0CciJyb3cAAKDQIekkZ2h0QXJyb3cAoNQhZQDlACsCbgBnAAABTFLWAugC5SFmdAABQVLcAuECciJyb3cAAKD4J+kkZ2h0QXJyb3cAoPon6SRnaHRBcnJvdwCg+SdpImdodAAAAUFU9gL7AnIicm93AACg0iFlAGUAAKCoInAAQQIGAwAAAAALA3Iicm93AACg0SFvJHduQXJyb3cAAKDVIWUlcnRpY2FsQmFyAACgJSJuAAADQUJMUlRhJAM2AzoDWgNxA3oDciJyb3cAAKGTIUJVLAMwA2EAcgAAoBMpcCNBcnJvdwAAoPUhciJldmUAEWPlIWZ00gJDAwAASwMAAFIDaSVnaHRWZWN0b3IAAKBQKWUkZVZlY3RvcgAAoF4p5SJjdG9yQqC9IWEAcgAAoFYpaSJnaHQA1AFiAwAAaQNlJGVWZWN0b3IAAKBfKeUiY3RvckKgwSFhAHIAAKBXKWUAZQBBoKQiciJyb3cAAKCnIXIAcgBvAPcAtAIAAWN0gwOHA3IA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YwAAoN8i4SFycnCgtiEAoD0pgKIqImJjZG9zACsVMBU6FT4VQRVyImNhcAAAoEgqAAFhdTQVNxVwAACgRipwAACgSipvAHQAAKCNInIAAKBFKgDgKiIA/gACYWxydksVURVuFXMVcgByAG2gtyEAoDwpeQCAAWV2dwBYFWUVaRVxAHACXxUAAAAAYxVyAGUA4wAXFXUA4wAZFWUAZQAAoM4iZSJkZ2UAAKDPImUAbgA7gKQApEBlI2Fycm93AAABbHJ7FX8V5SFmdACgtiFpImdodAAAoLchZQDkAG0VAAFjaYsVkRVvAG4AaQBuAPQAkwFuAHQAAKAxImwiY3R5AACgLSOACUFIYWJjZGVmaGlqbG9yc3R1d3oAuBW7Fb8V1RXgFegV+RUKFhUWHxZUFlcWZRbFFtsW7xb7FgUXChdyAPIAtAJhAHIAAKBlKQACZ2xyc8YVyhXOFdAV5yFlcgCgICDlIXRoAKA4IfIA9QxoAHagECAAoKMiawHZFd4VYSJyb3cAAKAPKWEA4wBfAgABYXnkFecV8iFvbg9hNGQAoUYhYW/tFfQVAAFnciEC8RVyAACgyiF0InNlcQAAoHcqgAFnbG0A/xUCFgUWO4CwALBAdABhALRjcCJ0eXYAAKCxKQABaXIOFhIW8yFodACgfykA4DXYId1hAHIAAAFschsWHRYAoMMhAKDCIYACYWVnc3YAKBauAjYWOhY+Fm0AAKHEIm9zLhY0Fm4AZABzoMQi9SFpdACgZiZhIm1tYQDdY2kAbgAAoPIiAKH3AGlvQxZRFmQAZQAAgfcAO29KFksW90BuI3RpbWVzAACgxyJuAPgAUBZjAHkAUmRjAG8CXhYAAAAAYhZyAG4AAKAeI28AcAAAoA0jgAJscHR1dwBuFnEWdRaSFp4W7CFhciRgZgAA4DXYVd0AotkCZW1wc30WhBaJFo0WcQBkoFAibwB0AACgUSJpIm51cwAAoDgi7CF1cwCgFCLxInVhcmUAoKEiYgBsAGUAYgBhAHIAdwBlAGQAZwDlANcAbgCAAWFkaAClFqoWtBZyAHIAbwD3APUMbwB3AG4AYQByAHIAbwB3APMA8xVhI3Jwb29uAAABbHK8FsAWZQBmAPQAHBZpAGcAaAD0AB4WYgHJFs8WawBhAHIAbwD3AJILbwLUFgAAAADYFnIAbgAAoB8jbwBwAACgDCOAAWNvdADhFukW7BYAAXJ55RboFgDgNdi53FVkbAAAoPYp8iFvaxFhAAFkcvMW9xZvAHQAAKDxImkA5qC/JVsSAAFhaP8WAhdyAPIANQNhAPIA1wvhIm5nbGUAoKYpAAFjaQ4XEBd5AF9k5yJyYXJyAKD/JwAJRGFjZGVmZ2xtbm9wcXJzdHV4MRc4F0YXWxcyBF4XaRd5F40XrBe0F78X2RcVGCEYLRg1GEAYAAFEbzUXgRZvAPQA+BUAAWNzPBdCF3UAdABlADuA6QDpQPQhZXIAoG4qAAJhaW95TRdQF1YXWhfyIW9uG2FyAGOgViI7gOoA6kDsIW9uAKBVIk1kbwB0ABdhAAFEcmIXZhdvAHQAAKBSIgDgNdgi3XKhmipuF3QXYQB2AGUAO4DoAOhAZKCWKm8AdAAAoJgqgKGZKmlscwCAF4UXhxfuInRlcnMAoOcjAKATIWSglSpvAHQAAKCXKoABYXBzAJMXlheiF2MAcgATYXQAeQBzogUinxcAAAAAoRdlAHQAAKAFInAAMaADIDMBqRerFwCgBCAAoAUgAAFnc7AXsRdLYXAAAKACIAABZ3C4F7sXbwBuABlhZgAA4DXYVt2AAWFscwDFF8sXzxdyAHOg1SJsAACg4yl1AHMAAKBxKmkAAKG1A2x21RfYF28AbgC1Y/VjAAJjc3V24BfoF/0XEBgAAWlv5BdWF3IAYwAAoFYiaQLuFwAAAADwF+0ADQThIW50AAFnbPUX+Rd0AHIAAKCWKuUhc3MAoJUqgAFhZWkAAxgGGAoYbABzAD1gcwB0AACgXyJ2AESgYSJEAACgeCrwImFyc2wAoOUpAAFEYRkYHRhvAHQAAKBTInIAcgAAoHEpgAFjZGkAJxgqGO0XcgAAoC8hbwD0AIwCAAFhaDEYMhi3YzuA8ADwQAABbXI5GD0YbAA7gOsA60BvAACgrCCAAWNpcABGGEgYSxhsACFgcwD0ACwEAAFlb08YVxhjAHQAYQB0AGkAbwDuABoEbgBlAG4AdABpAGEAbADlADME4Ql1GAAAgRgAAIMYiBgAAAAAoRilGAAAqhgAALsYvhjRGAAA1xgnGWwAbABpAG4AZwBkAG8AdABzAGUA8QBlF3kARGRtImFsZQAAoEAmgAFpbHIAjRiRGJ0Y7CFpZwCgA/tpApcYAAAAAJoYZwAAoAD7aQBnAACgBPsA4DXYI93sIWlnAKAB++whaWcA4GYAagCAAWFsdACvGLIYthh0AACgbSZpAGcAAKAC+24AcwAAoLElbwBmAJJh8AHCGAAAxhhmAADgNdhX3QABYWvJGMwYbADsAGsEdqDUIgCg2SphI3J0aW50AACgDSoAAWFv2hgiGQABY3PeGB8ZsQPnGP0YBRkSGRUZAAAdGbID7xjyGPQY9xj5GAAA+xg7gL0AvUAAoFMhO4C8ALxAAKBVIQCgWSEAoFshswEBGQAAAxkAoFQhAKBWIbQCCxkOGQAAAAAQGTuAvgC+QACgVyEAoFwhNQAAoFghtgEZGQAAGxkAoFohAKBdITgAAKBeIWwAAKBEIHcAbgAAoCIjYwByAADgNdi73IAIRWFiY2RlZmdpamxub3JzdHYARhlKGVoZXhlmGWkZkhmWGZkZnRmgGa0ZxhnLGc8Z4BkjGmygZyIAoIwqgAFjbXAAUBlTGVgZ9SF0ZfVhbQBhAOSgswM6FgCghipyImV2ZQAfYQABaXliGWUZcgBjAB1hM2RvAHQAIWGAoWUibHFzAMYEcBl6GfGhZSLOBAAAdhlsAGEAbgD0AN8EgKF+KmNkbACBGYQZjBljAACgqSpvAHQAb6CAKmyggioAoIQqZeDbIgD+cwAAoJQqcgAA4DXYJN3noGsirATtIWVsAKA3IWMAeQBTZIChdyJFYWoApxmpGasZAKCSKgCgpSoAoKQqAAJFYWVztBm2Gb0ZwhkAoGkicABwoIoq8iFveACgiipxoIgq8aCIKrUZaQBtAACg5yJwAGYAAOA12FjdYQB2AOUAYwIAAWNp0xnWGXIAAKAKIW0AAKFzImVs3BneGQCgjioAoJAqAIM+ADtjZGxxco0E6xn0GfgZ/BkBGgABY2nvGfEZAKCnKnIAAKB6Km8AdAAAoNci0CFhcgCglSl1ImVzdAAAoHwqgAJhZGVscwAKGvQZFhrVBCAa8AEPGgAAFBpwAHIAbwD4AFkZcgAAoHgpcQAAAWxxxAQbGmwAZQBzAPMASRlpAO0A5AQAAWVuJxouGnIjdG5lcXEAAOBpIgD+xQAsGgAFQWFiY2Vma29zeUAaQxpmGmoabRqDGocalhrCGtMacgDyAMwCAAJpbG1yShpOGlAaVBpyAHMA8ABxD2YAvWBpAGwA9AASBQABZHJYGlsaYwB5AEpkAKGUIWN3YBpkGmkAcgAAoEgpAKCtIWEAcgAAoA8h6SFyYyVhgAFhbHIAcxp7Gn8a8iF0c3WgZSZpAHQAAKBlJuwhaXAAoCYg4yFvbgCguSJyAADgNdgl3XMAAAFld4wakRphInJvdwAAoCUpYSJyb3cAAKAmKYACYW1vcHIAnxqjGqcauhq+GnIAcgAAoP8h9CFodACgOyJrAAABbHKsGrMaZSRmdGFycm93AACgqSHpJGdodGFycm93AKCqIWYAAOA12Fnd4iFhcgCgFSCAAWNsdADIGswa0BpyAADgNdi93GEAcwDoAGka8iFvaydhAAFicNca2xr1IWxsAKBDIOghZW4AoBAg4Qr2GgAA/RoAAAgbExsaGwAAIRs7GwAAAAA+G2IbmRuVG6sbAACyG80b0htjAHUAdABlADuA7QDtQAChYyBpeQEbBhtyAGMAO4DuAO5AOGQAAWN4CxsNG3kANWRjAGwAO4ChAKFAAAFmcssCFhsA4DXYJt1yAGEAdgBlADuA7ADsQIChSCFpbm8AJxsyGzYbAAFpbisbLxtuAHQAAKAMKnQAAKAtIuYhaW4AoNwpdABhAACgKSHsIWlnM2GAAWFvcABDG1sbXhuAAWNndABJG0sbWRtyACthgAFlbHAAcQVRG1UbaQBuAOUAyAVhAHIA9AByBWgAMWFmAACgtyJlAGQAtWEAoggiY2ZvdGkbbRt1G3kb4SFyZQCgBSFpAG4AdKAeImkAZQAAoN0pZABvAPQAWxsAoisiY2VscIEbhRuPG5QbYQBsAACguiIAAWdyiRuNG2UAcgDzACMQ4wCCG2EicmhrAACgFyryIW9kAKA8KgACY2dwdJ8boRukG6gbeQBRZG8AbgAvYWYAAOA12FrdYQC5Y3UAZQBzAHQAO4C/AL9AAAFjabUbuRtyAADgNdi+3G4AAKIIIkVkc3bCG8QbyBvQAwCg+SJvAHQAAKD1Inag9CIAoPMiaaBiIOwhZGUpYesB1hsAANkbYwB5AFZkbAA7gO8A70AAA2NmbW9zdeYb7hvyG/Ub+hsFHAABaXnqG+0bcgBjADVhOWRyAADgNdgn3eEhdGg3YnAAZgAA4DXYW93jAf8bAAADHHIAAOA12L/c8iFjeVhk6yFjeVRkAARhY2ZnaGpvcxUcGhwiHCYcKhwtHDAcNRzwIXBhdqC6A/BjAAFleR4cIRzkIWlsN2E6ZHIAAOA12CjdciJlZW4AOGFjAHkARWRjAHkAXGRwAGYAAOA12FzdYwByAADgNdjA3IALQUJFSGFiY2RlZmdoamxtbm9wcnN0dXYAXhxtHHEcdRx5HN8cBx0dHTwd3B3tHfEdAR4EHh0eLB5FHrwewx7hHgkfPR9LH4ABYXJ0AGQcZxxpHHIA8gBvB/IAxQLhIWlsAKAbKeEhcnIAoA4pZ6BmIgCgiyphAHIAAKBiKWMJjRwAAJAcAACVHAAAAAAAAAAAAACZHJwcAACmHKgcrRwAANIc9SF0ZTph7SJwdHl2AKC0KXIAYQDuAFoG4iFkYbtjZwAAoegnZGyhHKMcAKCRKeUAiwYAoIUqdQBvADuAqwCrQHIAgKOQIWJmaGxwc3QAuhy/HMIcxBzHHMoczhxmoOQhcwAAoB8pcwAAoB0p6wCyGnAAAKCrIWwAAKA5KWkAbQAAoHMpbAAAoKIhAKGrKmFl1hzaHGkAbAAAoBkpc6CtKgDgrSoA/oABYWJyAOUc6RztHHIAcgAAoAwpcgBrAACgcicAAWFr8Rz4HGMAAAFla/Yc9xx7YFtgAAFlc/wc/hwAoIspbAAAAWR1Ax0FHQCgjykAoI0pAAJhZXV5Dh0RHRodHB3yIW9uPmEAAWRpFR0YHWkAbAA8YewAowbiAPccO2QAAmNxcnMkHScdLB05HWEAAKA2KXUAbwDyoBwgqhEAAWR1MB00HeghYXIAoGcpcyJoYXIAAKBLKWgAAKCyIQCiZCJmZ3FzRB1FB5Qdnh10AIACYWhscnQATh1WHWUdbB2NHXIicm93AHSgkCFhAOkAzxxhI3Jwb29uAAABZHVeHWId7yF3bgCgvSFwAACgvCHlJGZ0YXJyb3dzAKDHIWkiZ2h0AIABYWhzAHUdex2DHXIicm93APOglCGdBmEAcgBwAG8AbwBuAPMAzgtxAHUAaQBnAGEAcgByAG8A9wBlGugkcmVldGltZXMAoMsi8aFkIk0HAACaHWwAYQBuAPQAXgcAon0qY2Rnc6YdqR2xHbcdYwAAoKgqbwB0AG+gfypyoIEqAKCDKmXg2iIA/nMAAKCTKoACYWRlZ3MAwB3GHcod1h3ZHXAAcAByAG8A+ACmHG8AdAAAoNYicQAAAWdxzx3SHXQA8gBGB2cAdADyAHQcdADyAFMHaQDtAGMHgAFpbHIA4h3mHeod8yFodACgfClvAG8A8gDKBgDgNdgp3UWgdiIAoJEqYQH1Hf4dcgAAAWR1YB35HWygvCEAoGopbABrAACghCVjAHkAWWQAomoiYWNodAweDx4VHhkecgDyAGsdbwByAG4AZQDyAGAW4SFyZACgaylyAGkAAKD6JQABaW8hHiQe5CFvdEBh9SFzdGGgsCPjIWhlAKCwIwACRWFlczMeNR48HkEeAKBoInAAcKCJKvIhb3gAoIkqcaCHKvGghyo0HmkAbQAAoOYiAARhYm5vcHR3elIeXB5fHoUelh6mHqsetB4AAW5yVh5ZHmcAAKDsJ3IAAKD9IXIA6wCwBmcAgAFsbXIAZh52Hnse5SFmdAABYXKIB2weaQBnAGgAdABhAHIAcgBvAPcAkwfhInBzdG8AoPwnaQBnAGgAdABhAHIAcgBvAPcAmgdwI2Fycm93AAABbHKNHpEeZQBmAPQAxhxpImdodAAAoKwhgAFhZmwAnB6fHqIecgAAoIUpAOA12F3ddQBzAACgLSppIm1lcwAAoDQqYQGvHrMecwB0AACgFyLhAIoOZaHKJbkeRhLuIWdlAKDKJWEAcgBsoCgAdAAAoJMpgAJhY2htdADMHs8e1R7bHt0ecgDyAJ0GbwByAG4AZQDyANYWYQByAGSgyyEAoG0pAKAOIHIAaQAAoL8iAANhY2hpcXTrHu8e1QfzHv0eBh/xIXVvAKA5IHIAAOA12MHcbQDloXIi+h4AAPweAKCNKgCgjyoAAWJ19xwBH28AcqAYIACgGiDyIW9rQmEAhDwAO2NkaGlscXJCBhcfxh0gHyQfKB8sHzEfAAFjaRsfHR8AoKYqcgAAoHkqcgBlAOUAkx3tIWVzAKDJIuEhcnIAoHYpdSJlc3QAAKB7KgABUGk1HzkfYQByAACglillocMlAgdfEnIAAAFkdUIfRx9zImhhcgAAoEop6CFhcgCgZikAAWVuTx9WH3IjdG5lcXEAAOBoIgD+xQBUHwAHRGFjZGVmaGlsbm9wc3VuH3Ifoh+rH68ftx+7H74f5h/uH/MfBwj/HwsgxCFvdACgOiIAAmNscHJ5H30fiR+eH3IAO4CvAK9AAAFldIEfgx8AoEImZaAgJ3MAZQAAoCAnc6CmIXQAbwCAoaYhZGx1AJQfmB+cH28AdwDuAHkDZQBmAPQA6gbwAOkO6yFlcgCgriUAAW95ph+qH+0hbWEAoCkqPGThIXNoAKAUIOElc3VyZWRhbmdsZQCgISJyAADgNdgq3W8AAKAnIYABY2RuAMQfyR/bH3IAbwA7gLUAtUBhoiMi0B8AANMf1x9zAPQAKxFpAHIAAKDwKm8AdAA7gLcAt0B1AHMA4qESIh4TAADjH3WgOCIAoCoqYwHqH+0fcAAAoNsq8gB+GnAAbAB1APMACAgAAWRw9x/7H+UhbHMAoKciZgAA4DXYXt0AAWN0AyAHIHIAAOA12MLc8CFvcwCgPiJsobwDECAVIPQiaW1hcACguCJhAPAAEyAADEdMUlZhYmNkZWZnaGlqbG1vcHJzdHV2dzwgRyBmIG0geSCqILgg2iDeIBEhFSEyIUMhTSFQIZwhnyHSIQAiIyKLIrEivyIUIwABZ3RAIEMgAODZIjgD9uBrItIgBwmAAWVsdABNIF8gYiBmAHQAAAFhclMgWCByInJvdwAAoM0h6SRnaHRhcnJvdwCgziEA4NgiOAP24Goi0iBfCekkZ2h0YXJyb3cAoM8hAAFEZHEgdSDhIXNoAKCvIuEhc2gAoK4igAJiY25wdACCIIYgiSCNIKIgbABhAACgByL1IXRlRGFnAADgICLSIACiSSJFaW9wlSCYIJwgniAA4HAqOANkAADgSyI4A3MASWFyAG8A+AAyCnUAcgBhoG4mbADzoG4mmwjzAa8gAACzIHAAO4CgAKBAbQBwAOXgTiI4AyoJgAJhZW91eQDBIMogzSDWINkg8AHGIAAAyCAAoEMqbwBuAEhh5CFpbEZhbgBnAGSgRyJvAHQAAOBtKjgDcAAAoEIqPWThIXNoAKATIACjYCJBYWRxc3jpIO0g+SD+IAIhDCFyAHIAAKDXIXIAAAFocvIg9SBrAACgJClvoJch9wAGD28AdAAA4FAiOAN1AGkA9gC7CAABZWkGIQohYQByAACgKCntAN8I6SFzdPOgBCLlCHIAAOA12CvdAAJFZXN0/wgcISshLiHxoXEiIiEAABMJ8aFxIgAJAAAnIWwAYQBuAPQAEwlpAO0AGQlyoG8iAKBvIoABQWFwADghOyE/IXIA8gBeIHIAcgAAoK4hYQByAACg8ipzogsiSiEAAAAAxwtkoPwiAKD6ImMAeQBaZIADQUVhZGVzdABcIV8hYiFmIWkhkyGWIXIA8gBXIADgZiI4A3IAcgAAoJohcgAAoCUggKFwImZxcwBwIYQhjiF0AAABYXJ1IXohcgByAG8A9wBlIWkAZwBoAHQAYQByAHIAbwD3AD4h8aFwImAhAACKIWwAYQBuAPQAZwlz4H0qOAMAoG4iaQDtAG0JcqBuImkA5aDqIkUJaQDkADoKAAFwdKMhpyFmAADgNdhf3YCBrAA7aW4AriGvIcchrEBuAIChCSJFZHYAtyG6Ib8hAOD5IjgDbwB0AADg9SI4A+EB1gjEIcYhAKD3IgCg9iJpAHagDCLhAagJzyHRIQCg/iIAoP0igAFhb3IA2CHsIfEhcgCAoSYiYXN0AOAh5SHpIWwAbABlAOwAywhsAADg/SrlIADgAiI4A2wiaW50AACgFCrjoYAi9yEAAPohdQDlAJsJY+CvKjgDZaCAIvEAkwkAAkFhaXQHIgoiFyIeInIA8gBsIHIAcgAAoZshY3cRIhQiAOAzKTgDAOCdITgDZyRodGFycm93AACgmyFyAGkA5aDrIr4JgANjaGltcHF1AC8iPCJHIpwhTSJQIloigKGBImNlcgA2Iv0JOSJ1AOUABgoA4DXYw9zvIXJ0bQKdIQAAAABEImEAcgDhAOEhbQBloEEi8aBEIiYKYQDyAMsIcwB1AAABYnBWIlgi5QDUCeUA3wmAAWJjcABgInMieCKAoYQiRWVzAGci7glqIgDgxSo4A2UAdABl4IIi0iBxAPGgiCJoImMAZaCBIvEA/gmAoYUiRWVzAH8iFgqCIgDgxio4A2UAdABl4IMi0iBxAPGgiSKAIgACZ2lscpIilCKaIpwi7AAMCWwAZABlADuA8QDxQOcAWwlpI2FuZ2xlAAABbHKkIqoi5SFmdGWg6iLxAEUJaSJnaHQAZaDrIvEAvgltoL0DAKEjAGVzuCK8InIAbwAAoBYhcAAAoAcggARESGFkZ2lscnMAziLSItYi2iLeIugi7SICIw8j4SFzaACgrSLhIXJyAKAEKXAAAOBNItIg4SFzaACgrCIAAWV04iLlIgDgZSLSIADgPgDSIG4iZmluAACg3imAAUFldADzIvci+iJyAHIAAKACKQDgZCLSIHLgPADSIGkAZQAA4LQi0iAAAUF0BiMKI3IAcgAAoAMp8iFpZQDgtSLSIGkAbQAA4Dwi0iCAAUFhbgAaIx4jKiNyAHIAAKDWIXIAAAFociMjJiNrAACgIylvoJYh9wD/DuUhYXIAoCcpUxJqFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVCMAAF4jaSN/I4IjjSOeI8AUAAAAAKYjwCMAANoj3yMAAO8jHiQvJD8kRCQAAWNzVyNsFHUAdABlADuA8wDzQAABaXlhI2cjcgBjoJoiO4D0APRAPmSAAmFiaW9zAHEjdCN3I3EBeiNzAOgAdhTsIWFjUWF2AACgOCrvIWxkAKC8KewhaWdTYQABY3KFI4kjaQByAACgvykA4DXYLN1vA5QjAAAAAJYjAACcI24A22JhAHYAZQA7gPIA8kAAoMEpAAFibaEjjAphAHIAAKC1KQACYWNpdKwjryO6I70jcgDyAFkUAAFpcrMjtiNyAACgvinvIXNzAKC7KW4A5QDZCgCgwCmAAWFlaQDFI8gjyyNjAHIATWFnAGEAyWOAAWNkbgDRI9Qj1iPyIW9uv2MAoLYpdQDzAHgBcABmAADgNdhg3YABYWVsAOQj5yPrI3IAAKC3KXIAcAAAoLkpdQDzAHwBAKMoImFkaW9zdvkj/CMPJBMkFiQbJHIA8gBeFIChXSplZm0AAyQJJAwkcgBvoDQhZgAAoDQhO4CqAKpAO4C6ALpA5yFvZgCgtiJyAACgVipsIm9wZQAAoFcqAKBbKoABY2xvACMkJSQrJPIACCRhAHMAaAA7gPgA+EBsAACgmCJpAGwBMyQ4JGQAZQA7gPUA9UBlAHMAYaCXInMAAKA2Km0AbAA7gPYA9kDiIWFyAKA9I+EKXiQAAHokAAB8JJQkAACYJKkkAAAAALUkEQsAAPAkAAAAAAQleiUAAIMlcgCAoSUiYXN0AGUkbyQBCwCBtgA7bGokayS2QGwAZQDsABgDaQJ1JAAAAAB4JG0AAKDzKgCg/Sp5AD9kcgCAAmNpbXB0AIUkiCSLJJkSjyRuAHQAJWBvAGQALmBpAGwAAKAwIOUhbmsAoDEgcgAA4DXYLd2AAWltbwCdJKAkpCR2oMYD1WNtAGEA9AD+B24AZQAAoA4m9KHAA64kAAC0JGMjaGZvcmsAAKDUItZjAAFhdbgkxCRuAAABY2u9JMIkawBooA8hAKAOIfYAaRpzAACkKwBhYmNkZW1zdNMkIRPXJNsk4STjJOck6yTjIWlyAKAjKmkAcgAAoCIqAAFvdYsW3yQAoCUqAKByKm4AO4CxALFAaQBtAACgJip3AG8AAKAnKoABaXB1APUk+iT+JO4idGludACgFSpmAADgNdhh3W4AZAA7gKMAo0CApHoiRWFjZWlub3N1ABMlFSUYJRslTCVRJVklSSV1JQCgsypwAACgtyp1AOUAPwtjoK8qgKJ6ImFjZW5zACclLSU0JTYlSSVwAHAAcgBvAPgAFyV1AHIAbAB5AGUA8QA/C/EAOAuAAWFlcwA8JUElRSXwInByb3gAoLkqcQBxAACgtSppAG0AAKDoImkA7QBEC20AZQDzoDIgIguAAUVhcwBDJVclRSXwAEAlgAFkZnAATwtfJXElgAFhbHMAZSVpJW0l7CFhcgCgLiPpIW5lAKASI/UhcmYAoBMjdKAdIu8AWQvyIWVsAKCwIgABY2l9JYElcgAA4DXYxdzIY24iY3NwAACgCCAAA2Zpb3BzdZElKxuVJZolnyWkJXIAAOA12C7dcABmAADgNdhi3XIiaW1lAACgVyBjAHIAAOA12MbcgAFhZW8AqiW6JcAldAAAAWVpryW2JXIAbgBpAG8AbgDzABkFbgB0AACgFipzAHQAZaA/APEACRj0AG0LgApBQkhhYmNkZWZoaWxtbm9wcnN0dXgA4yXyJfYl+iVpJpAmpia9JtUm5ib4JlonaCdxJ3UnnietJ7EnyCfiJ+cngAFhcnQA6SXsJe4lcgDyAJkM8gD6AuEhaWwAoBwpYQByAPIA3BVhAHIAAKBkKYADY2RlbnFydAAGJhAmEyYYJiYmKyZaJgABZXUKJg0mAOA9IjEDdABlAFVhaQDjACAN7SJwdHl2AKCzKWcAgKHpJ2RlbAAgJiImJCYAoJIpAKClKeUA9wt1AG8AO4C7ALtAcgAApZIhYWJjZmhscHN0dz0mQCZFJkcmSiZMJk4mUSZVJlgmcAAAoHUpZqDlIXMAAKAgKQCgMylzAACgHinrALka8ACVHmwAAKBFKWkAbQAAoHQpbAAAoKMhAKCdIQABYWleJmImaQBsAACgGilvAG6gNiJhAGwA8wB2C4ABYWJyAG8mciZ2JnIA8gAvEnIAawAAoHMnAAFha3omgSZjAAABZWt/JoAmfWBdYAABZXOFJocmAKCMKWwAAAFkdYwmjiYAoI4pAKCQKQACYWV1eZcmmiajJqUm8iFvbllhAAFkaZ4moSZpAGwAV2HsAA8M4gCAJkBkAAJjbHFzrSawJrUmuiZhAACgNylkImhhcgAAoGkpdQBvAPKgHSCjAWgAAKCzIYABYWNnAMMm0iaUC2wAgKEcIWlwcwDLJs4migxuAOUAoAxhAHIA9ADaC3QAAKCtJYABaWxyANsm3ybjJvMhaHQAoH0pbwBvAPIANgwA4DXYL90AAWFv6ib1JnIAAAFkde8m8SYAoMEhbKDAIQCgbCl2oMED8WOAAWducwD+Jk4nUCdoAHQAAANhaGxyc3QKJxInISc1Jz0nRydyInJvdwB0oJIhYQDpAFYmYSNycG9vbgAAAWR1GiceJ28AdwDuAPAmcAAAoMAh5SFmdAABYWgnJy0ncgByAG8AdwDzAAkMYQByAHAAbwBvAG4A8wATBGklZ2h0YXJyb3dzAACgySFxAHUAaQBnAGEAcgByAG8A9wBZJugkcmVldGltZXMAoMwiZwDaYmkAbgBnAGQAbwB0AHMAZQDxABwYgAFhaG0AYCdjJ2YncgDyAAkMYQDyABMEAKAPIG8idXN0AGGgsSPjIWhlAKCxI+0haWQAoO4qAAJhYnB0fCeGJ4knmScAAW5ygCeDJ2cAAKDtJ3IAAKD+IXIA6wAcDIABYWZsAI8nkieVJ3IAAKCGKQDgNdhj3XUAcwAAoC4qaSJtZXMAAKA1KgABYXCiJ6gncgBnoCkAdAAAoJQp7yJsaW50AKASKmEAcgDyADwnAAJhY2hxuCe8J6EMwCfxIXVvAKA6IHIAAOA12MfcAAFidYAmxCdvAPKgGSCoAYABaGlyAM4n0ifWJ3IAZQDlAE0n7SFlcwCgyiJpAIChuSVlZmwAXAxjEt4n9CFyaQCgzinsInVoYXIAoGgpAKAeIWENBSgJKA0oSyhVKIYoAACLKLAoAAAAAOMo5ygAABApJCkxKW0pcSmHKaYpAACYKgAAAACxKmMidXRlAFthcQB1AO8ABR+ApHsiRWFjZWlucHN5ABwoHignKCooLygyKEEoRihJKACgtCrwASMoAAAlKACguCpvAG4AYWF1AOUAgw1koLAqaQBsAF9hcgBjAF1hgAFFYXMAOCg6KD0oAKC2KnAAAKC6KmkAbQAAoOki7yJsaW50AKATKmkA7QCIDUFkbwB0AGKixSKRFgAAAABTKACgZiqAA0FhY21zdHgAYChkKG8ocyh1KHkogihyAHIAAKDYIXIAAAFocmkoayjrAJAab6CYIfcAzAd0ADuApwCnQGkAO2D3IWFyAKApKW0AAAFpbn4ozQBuAHUA8wDOAHQAAKA2J3IA7+A12DDdIxkAAmFjb3mRKJUonSisKHIAcAAAoG8mAAFoeZkonChjAHkASWRIZHIAdABtAqUoAAAAAKgoaQDkAFsPYQByAGEA7ABsJDuArQCtQAABZ22zKLsobQBhAAChwwNmdroouijCY4CjPCJkZWdsbnByAMgozCjPKNMo1yjaKN4obwB0AACgairxoEMiCw5FoJ4qAKCgKkWgnSoAoJ8qZQAAoEYi7CF1cwCgJCrhIXJyAKByKWEAcgDyAPwMAAJhZWl07Sj8KAEpCCkAAWxz8Sj4KGwAcwBlAHQAbQDpAH8oaABwAACgMyrwImFyc2wAoOQpAAFkbFoPBSllAACgIyNloKoqc6CsKgDgrCoA/oABZmxwABUpGCkfKfQhY3lMZGKgLwBhoMQpcgAAoD8jZgAA4DXYZN1hAAABZHIoKRcDZQBzAHWgYCZpAHQAAKBgJoABY3N1ADYpRilhKQABYXU6KUApcABzoJMiAOCTIgD+cABzoJQiAOCUIgD+dQAAAWJwSylWKQChjyJlcz4NUCllAHQAZaCPIvEAPw0AoZAiZXNIDVspZQB0AGWgkCLxAEkNAKGhJWFmZilbBHIAZQFrKVwEAKChJWEAcgDyAAMNAAJjZW10dyl7KX8pgilyAADgNdjI3HQAbQDuAM4AaQDsAAYpYQByAOYAVw0AAWFyiimOKXIA5qAGJhESAAFhbpIpoylpImdodAAAAWVwmSmgKXAAcwBpAGwAbwDuANkXaADpAKAkcwCvYIACYmNtbnAArin8KY4NJSooKgCkgiJFZGVtbnByc7wpvinCKcgpzCnUKdgp3CkAoMUqbwB0AACgvSpkoIYibwB0AACgwyr1IWx0AKDBKgABRWXQKdIpAKDLKgCgiiLsIXVzAKC/KuEhcnIAoHkpgAFlaXUA4inxKfQpdAAAoYIiZW7oKewpcQDxoIYivSllAHEA8aCKItEpbQAAoMcqAAFicPgp+ikAoNUqAKDTKmMAgKJ7ImFjZW5zAAcqDSoUKhYqRihwAHAAcgBvAPgAIyh1AHIAbAB5AGUA8QCDDfEAfA2AAWFlcwAcKiIqPShwAHAAcgBvAPgAPChxAPEAOShnAACgaiYApoMiMTIzRWRlaGxtbnBzPCo/KkIqRSpHKlIqWCpjKmcqaypzKncqO4C5ALlAO4CyALJAO4CzALNAAKDGKgABb3NLKk4qdAAAoL4qdQBiAACg2CpkoIcibwB0AACgxCpzAAABb3VdKmAqbAAAoMknYgAAoNcq4SFycgCgeyn1IWx0AKDCKgABRWVvKnEqAKDMKgCgiyLsIXVzAKDAKoABZWl1AH0qjCqPKnQAAKGDImVugyqHKnEA8aCHIkYqZQBxAPGgiyJwKm0AAKDIKgABYnCTKpUqAKDUKgCg1iqAAUFhbgCdKqEqrCpyAHIAAKDZIXIAAAFocqYqqCrrAJUab6CZIfcAxQf3IWFyAKAqKWwAaQBnADuA3wDfQOELzyrZKtwq6SrsKvEqAAD1KjQrAAAAAAAAAAAAAEwrbCsAAHErvSsAAAAAAADRK3IC1CoAAAAA2CrnIWV0AKAWI8RjcgDrAOUKgAFhZXkA4SrkKucq8iFvbmVh5CFpbGNhQmRvAPQAIg5sInJlYwAAoBUjcgAA4DXYMd0AAmVpa2/7KhIrKCsuK/IBACsAAAkrZQAAATRm6g0EK28AcgDlAOsNYQBzorgDECsAAAAAEit5AG0A0WMAAWNuFislK2sAAAFhcxsrIStwAHAAcgBvAPgAFw5pAG0AAKA8InMA8AD9DQABYXMsKyEr8AAXDnIAbgA7gP4A/kDsATgrOyswG2QA5QBnAmUAcwCAgdcAO2JkAEMrRCtJK9dAYaCgInIAAKAxKgCgMCqAAWVwcwBRK1MraSvhAAkh4qKkIlsrXysAAAAAYytvAHQAAKA2I2kAcgAAoPEqb+A12GXdcgBrAACg2irhAHgociJpbWUAAKA0IIABYWlwAHYreSu3K2QA5QC+DYADYWRlbXBzdACFK6MrmiunK6wrsCuzK24iZ2xlAACitSVkbHFykCuUK5ornCvvIXduAKC/JeUhZnRloMMl8QACBwCgXCJpImdodABloLkl8QBdDG8AdAAAoOwlaSJudXMAAKA6KuwhdXMAoDkqYgAAoM0p6SFtZQCgOyrlInppdW0AoOIjgAFjaHQAwivKK80rAAFyecYrySsA4DXYydxGZGMAeQBbZPIhb2tnYQABaW/UK9creAD0ANERaCJlYWQAAAFsct4r5ytlAGYAdABhAHIAcgBvAPcAXQbpJGdodGFycm93AKCgIQAJQUhhYmNkZmdobG1vcHJzdHV3CiwNLBEsHSwnLDEsQCxLLFIsYix6LIQsjyzLLOgs7Sz/LAotcgDyAAkDYQByAACgYykAAWNyFSwbLHUAdABlADuA+gD6QPIACQ1yAOMBIywAACUseQBeZHYAZQBtYQABaXkrLDAscgBjADuA+wD7QENkgAFhYmgANyw6LD0scgDyANEO7CFhY3FhYQDyAOAOAAFpckQsSCzzIWh0AKB+KQDgNdgy3XIAYQB2AGUAO4D5APlAYQFWLF8scgAAAWxyWixcLACgvyEAoL4hbABrAACggCUAAWN0Zix2LG8CbCwAAAAAcyxyAG4AZaAcI3IAAKAcI28AcAAAoA8jcgBpAACg+CUAAWFsfiyBLGMAcgBrYTuAqACoQAABZ3CILIssbwBuAHNhZgAA4DXYZt0AA2FkaGxzdZksniynLLgsuyzFLHIAcgBvAPcACQ1vAHcAbgBhAHIAcgBvAPcA2A5hI3Jwb29uAAABbHKvLLMsZQBmAPQAWyxpAGcAaAD0AF0sdQDzAKYOaQAAocUDaGzBLMIs0mNvAG4AxWPwI2Fycm93cwCgyCGAAWNpdADRLOEs5CxvAtcsAAAAAN4scgBuAGWgHSNyAACgHSNvAHAAAKAOI24AZwBvYXIAaQAAoPklYwByAADgNdjK3IABZGlyAPMs9yz6LG8AdAAAoPAi7CFkZWlhaQBmoLUlAKC0JQABYW0DLQYtcgDyAMosbAA7gPwA/EDhIm5nbGUAoKcpgAdBQkRhY2RlZmxub3Byc3oAJy0qLTAtNC2bLZ0toS2/LcMtxy3TLdgt3C3gLfwtcgDyABADYQByAHag6CoAoOkqYQBzAOgA/gIAAW5yOC08LechcnQAoJwpgANla25wcnN0AJkpSC1NLVQtXi1iLYItYQBwAHAA4QAaHG8AdABoAGkAbgDnAKEXgAFoaXIAoSmzJFotbwBwAPQAdCVooJUh7wD4JgABaXVmLWotZwBtAOEAuygAAWJwbi14LXMjZXRuZXEAceCKIgD+AODLKgD+cyNldG5lcQBx4IsiAP4A4MwqAP4AAWhyhi2KLWUAdADhABIraSNhbmdsZQAAAWxyki2WLeUhZnQAoLIiaSJnaHQAAKCzInkAMmThIXNoAKCiIoABZWxyAKcttC24LWKiKCKuLQAAAACyLWEAcgAAoLsicQAAoFoi7CFpcACg7iIAAWJ0vC1eD2EA8gBfD3IAAOA12DPddAByAOkAlS1zAHUAAAFicM0t0C0A4IIi0iAA4IMi0iBwAGYAAOA12GfdcgBvAPAAWQt0AHIA6QCaLQABY3XkLegtcgAA4DXYy9wAAWJw7C30LW4AAAFFZXUt8S0A4IoiAP5uAAABRWV/LfktAOCLIgD+6SJnemFnAKCaKYADY2Vmb3BycwANLhAuJS4pLiMuLi40LukhcmN1YQABZGkULiEuAAFiZxguHC5hAHIAAKBfKmUAcaAnIgCgWSLlIXJwAKAYIXIAAOA12DTdcABmAADgNdho3WWgQCJhAHQA6ABqD2MAcgAA4DXYzNzjCuQRUC4AAFQuAABYLmIuAAAAAGMubS5wLnQuAAAAAIguki4AAJouJxIqEnQAcgDpAB0ScgAA4DXYNd0AAUFhWy5eLnIA8gDnAnIA8gCTB75jAAFBYWYuaS5yAPIA4AJyAPIAjAdhAPAAeh5pAHMAAKD7IoABZHB0APgReS6DLgABZmx9LoAuAOA12GnddQDzAP8RaQBtAOUABBIAAUFhiy6OLnIA8gDuAnIA8gCaBwABY3GVLgoScgAA4DXYzdwAAXB0nS6hLmwAdQDzACUScgDpACASAARhY2VmaW9zdbEuvC7ELsguzC7PLtQu2S5jAAABdXm2LrsudABlADuA/QD9QE9kAAFpecAuwy5yAGMAd2FLZG4AO4ClAKVAcgAA4DXYNt1jAHkAV2RwAGYAAOA12GrdYwByAADgNdjO3AABY23dLt8ueQBOZGwAO4D/AP9AAAVhY2RlZmhpb3N38y73Lv8uAi8MLxAvEy8YLx0vIi9jInV0ZQB6YQABYXn7Lv4u8iFvbn5hN2RvAHQAfGEAAWV0Bi8KL3QAcgDmAB8QYQC2Y3IAAOA12DfdYwB5ADZk5yJyYXJyAKDdIXAAZgAA4DXYa91jAHIAAOA12M/cAAFqbiYvKC8AoA0gagAAoAwg"),Iu=kr("AAJhZ2xxBwARABMAFQBtAg0AAAAAAA8AcAAmYG8AcwAnYHQAPmB0ADxg9SFvdCJg");var J;(function(e){e[e.VALUE_LENGTH=49152]="VALUE_LENGTH",e[e.FLAG13=8192]="FLAG13",e[e.BRANCH_LENGTH=8064]="BRANCH_LENGTH",e[e.JUMP_TABLE=127]="JUMP_TABLE"})(J||(J={}));var Q;(function(e){e[e.NUM=35]="NUM",e[e.SEMI=59]="SEMI",e[e.EQUALS=61]="EQUALS",e[e.ZERO=48]="ZERO",e[e.NINE=57]="NINE",e[e.LOWER_A=97]="LOWER_A",e[e.LOWER_F=102]="LOWER_F",e[e.LOWER_X=120]="LOWER_X",e[e.LOWER_Z=122]="LOWER_Z",e[e.UPPER_A=65]="UPPER_A",e[e.UPPER_F=70]="UPPER_F",e[e.UPPER_Z=90]="UPPER_Z"})(Q||(Q={}));const Ir=32;function tn(e){return e>=Q.ZERO&&e<=Q.NINE}function xu(e){return e>=Q.UPPER_A&&e<=Q.UPPER_F||e>=Q.LOWER_A&&e<=Q.LOWER_F}function Su(e){return e>=Q.UPPER_A&&e<=Q.UPPER_Z||e>=Q.LOWER_A&&e<=Q.LOWER_Z||tn(e)}function Eu(e){return e===Q.EQUALS||Su(e)}var z;(function(e){e[e.EntityStart=0]="EntityStart",e[e.NumericStart=1]="NumericStart",e[e.NumericDecimal=2]="NumericDecimal",e[e.NumericHex=3]="NumericHex",e[e.NamedEntity=4]="NamedEntity"})(z||(z={}));var X;(function(e){e[e.Legacy=0]="Legacy",e[e.Strict=1]="Strict",e[e.Attribute=2]="Attribute"})(X||(X={}));class Cu{decodeTree;emitCodePoint;errors;constructor(t,n,i){this.decodeTree=t,this.emitCodePoint=n,this.errors=i}state=z.EntityStart;consumed=1;result=0;treeIndex=0;excess=1;decodeMode=X.Strict;runConsumed=0;startEntity(t){this.decodeMode=t,this.state=z.EntityStart,this.result=0,this.treeIndex=0,this.excess=1,this.consumed=1,this.runConsumed=0}write(t,n){switch(this.state){case z.EntityStart:return t.charCodeAt(n)===Q.NUM?(this.state=z.NumericStart,this.consumed+=1,this.stateNumericStart(t,n+1)):(this.state=z.NamedEntity,this.stateNamedEntity(t,n));case z.NumericStart:return this.stateNumericStart(t,n);case z.NumericDecimal:return this.stateNumericDecimal(t,n);case z.NumericHex:return this.stateNumericHex(t,n);case z.NamedEntity:return this.stateNamedEntity(t,n)}}stateNumericStart(t,n){return n>=t.length?-1:(t.charCodeAt(n)|Ir)===Q.LOWER_X?(this.state=z.NumericHex,this.consumed+=1,this.stateNumericHex(t,n+1)):(this.state=z.NumericDecimal,this.stateNumericDecimal(t,n))}stateNumericHex(t,n){for(;n<t.length;){const i=t.charCodeAt(n);if(tn(i)||xu(i)){const r=i<=Q.NINE?i-Q.ZERO:(i|Ir)-Q.LOWER_A+10;this.result=this.result*16+r,this.consumed++,n++}else return this.emitNumericEntity(i,3)}return-1}stateNumericDecimal(t,n){for(;n<t.length;){const i=t.charCodeAt(n);if(tn(i))this.result=this.result*10+(i-Q.ZERO),this.consumed++,n++;else return this.emitNumericEntity(i,2)}return-1}emitNumericEntity(t,n){if(this.consumed<=n)return this.errors?.absenceOfDigitsInNumericCharacterReference(this.consumed),0;if(t===Q.SEMI)this.consumed+=1;else if(this.decodeMode===X.Strict)return 0;return this.emitCodePoint(yu(this.result),this.consumed),this.errors&&(t!==Q.SEMI&&this.errors.missingSemicolonAfterCharacterReference(),this.errors.validateNumericCharacterReference(this.result)),this.consumed}stateNamedEntity(t,n){const{decodeTree:i}=this;let r=i[this.treeIndex],s=(r&J.VALUE_LENGTH)>>14;for(;n<t.length;){if(s===0&&(r&J.FLAG13)!==0){const c=(r&J.BRANCH_LENGTH)>>7;if(this.runConsumed===0){const l=r&J.JUMP_TABLE;if(t.charCodeAt(n)!==l)return this.result===0?0:this.emitNotTerminatedNamedEntity();n++,this.excess++,this.runConsumed++}for(;this.runConsumed<c;){if(n>=t.length)return-1;const l=this.runConsumed-1,A=i[this.treeIndex+1+(l>>1)],m=l%2===0?A&255:A>>8&255;if(t.charCodeAt(n)!==m)return this.runConsumed=0,this.result===0?0:this.emitNotTerminatedNamedEntity();n++,this.excess++,this.runConsumed++}this.runConsumed=0,this.treeIndex+=1+(c>>1),r=i[this.treeIndex],s=(r&J.VALUE_LENGTH)>>14}if(n>=t.length)break;const a=t.charCodeAt(n);if(a===Q.SEMI&&s!==0&&(r&J.FLAG13)!==0)return this.emitNamedEntityData(this.treeIndex,s,this.consumed+this.excess);if(this.treeIndex=Bu(i,r,this.treeIndex+Math.max(1,s),a),this.treeIndex<0)return this.result===0||this.decodeMode===X.Attribute&&(s===0||Eu(a))?0:this.emitNotTerminatedNamedEntity();if(r=i[this.treeIndex],s=(r&J.VALUE_LENGTH)>>14,s!==0){if(a===Q.SEMI)return this.emitNamedEntityData(this.treeIndex,s,this.consumed+this.excess);this.decodeMode!==X.Strict&&(r&J.FLAG13)===0&&(this.result=this.treeIndex,this.consumed+=this.excess,this.excess=0)}n++,this.excess++}return-1}emitNotTerminatedNamedEntity(){const{result:t,decodeTree:n}=this,i=(n[t]&J.VALUE_LENGTH)>>14;return this.emitNamedEntityData(t,i,this.consumed),this.errors?.missingSemicolonAfterCharacterReference(),this.consumed}emitNamedEntityData(t,n,i){const{decodeTree:r}=this;return this.emitCodePoint(n===1?r[t]&~(J.VALUE_LENGTH|J.FLAG13):r[t+1],i),n===3&&this.emitCodePoint(r[t+2],i),i}end(){switch(this.state){case z.NamedEntity:return this.result!==0&&(this.decodeMode!==X.Attribute||this.result===this.treeIndex)?this.emitNotTerminatedNamedEntity():0;case z.NumericDecimal:return this.emitNumericEntity(0,2);case z.NumericHex:return this.emitNumericEntity(0,3);case z.NumericStart:return this.errors?.absenceOfDigitsInNumericCharacterReference(this.consumed),0;case z.EntityStart:return 0}}}function Bu(e,t,n,i){const r=(t&J.BRANCH_LENGTH)>>7,s=t&J.JUMP_TABLE;if(r===0)return s!==0&&i===s?n:-1;if(s){const A=i-s;return A<0||A>=r?-1:e[n+A]-1}const a=r+1>>1;let c=0,l=r-1;for(;c<=l;){const A=c+l>>>1,m=A>>1,I=e[n+m]>>(A&1)*8&255;if(I<i)c=A+1;else if(I>i)l=A-1;else return e[n+a+A]}return-1}var x;(function(e){e[e.Tab=9]="Tab",e[e.NewLine=10]="NewLine",e[e.FormFeed=12]="FormFeed",e[e.CarriageReturn=13]="CarriageReturn",e[e.Space=32]="Space",e[e.ExclamationMark=33]="ExclamationMark",e[e.Number=35]="Number",e[e.Amp=38]="Amp",e[e.SingleQuote=39]="SingleQuote",e[e.DoubleQuote=34]="DoubleQuote",e[e.Dash=45]="Dash",e[e.Slash=47]="Slash",e[e.Zero=48]="Zero",e[e.Nine=57]="Nine",e[e.Semi=59]="Semi",e[e.Lt=60]="Lt",e[e.Eq=61]="Eq",e[e.Gt=62]="Gt",e[e.Questionmark=63]="Questionmark",e[e.UpperA=65]="UpperA",e[e.LowerA=97]="LowerA",e[e.UpperF=70]="UpperF",e[e.LowerF=102]="LowerF",e[e.UpperZ=90]="UpperZ",e[e.LowerZ=122]="LowerZ",e[e.LowerX=120]="LowerX",e[e.OpeningSquareBracket=91]="OpeningSquareBracket"})(x||(x={}));var f;(function(e){e[e.Text=1]="Text",e[e.BeforeTagName=2]="BeforeTagName",e[e.InTagName=3]="InTagName",e[e.InSelfClosingTag=4]="InSelfClosingTag",e[e.BeforeClosingTagName=5]="BeforeClosingTagName",e[e.InClosingTagName=6]="InClosingTagName",e[e.AfterClosingTagName=7]="AfterClosingTagName",e[e.BeforeAttributeName=8]="BeforeAttributeName",e[e.InAttributeName=9]="InAttributeName",e[e.AfterAttributeName=10]="AfterAttributeName",e[e.BeforeAttributeValue=11]="BeforeAttributeValue",e[e.InAttributeValueDq=12]="InAttributeValueDq",e[e.InAttributeValueSq=13]="InAttributeValueSq",e[e.InAttributeValueNq=14]="InAttributeValueNq",e[e.BeforeDeclaration=15]="BeforeDeclaration",e[e.InDeclaration=16]="InDeclaration",e[e.InProcessingInstruction=17]="InProcessingInstruction",e[e.BeforeComment=18]="BeforeComment",e[e.CDATASequence=19]="CDATASequence",e[e.DeclarationSequence=20]="DeclarationSequence",e[e.InSpecialComment=21]="InSpecialComment",e[e.InCommentLike=22]="InCommentLike",e[e.SpecialStartSequence=23]="SpecialStartSequence",e[e.InSpecialTag=24]="InSpecialTag",e[e.InPlainText=25]="InPlainText",e[e.InEntity=26]="InEntity"})(f||(f={}));function me(e){return e===x.Space||e===x.NewLine||e===x.Tab||e===x.FormFeed||e===x.CarriageReturn}function Ne(e){return e===x.Slash||e===x.Gt||me(e)}function _u(e){return e>=x.LowerA&&e<=x.LowerZ||e>=x.UpperA&&e<=x.UpperZ}var $;(function(e){e[e.NoValue=0]="NoValue",e[e.Unquoted=1]="Unquoted",e[e.Single=2]="Single",e[e.Double=3]="Double"})($||($={}));const E={Empty:new Uint8Array(0),Cdata:new Uint8Array([67,68,65,84,65,91]),CdataEnd:new Uint8Array([93,93,62]),CommentEnd:new Uint8Array([45,45,33,62]),Doctype:new Uint8Array([100,111,99,116,121,112,101]),IframeEnd:new Uint8Array([60,47,105,102,114,97,109,101]),NoembedEnd:new Uint8Array([60,47,110,111,101,109,98,101,100]),NoframesEnd:new Uint8Array([60,47,110,111,102,114,97,109,101,115]),Plaintext:new Uint8Array([60,47,112,108,97,105,110,116,101,120,116]),ScriptEnd:new Uint8Array([60,47,115,99,114,105,112,116]),StyleEnd:new Uint8Array([60,47,115,116,121,108,101]),TitleEnd:new Uint8Array([60,47,116,105,116,108,101]),TextareaEnd:new Uint8Array([60,47,116,101,120,116,97,114,101,97]),XmpEnd:new Uint8Array([60,47,120,109,112])},Du=new Map([[E.IframeEnd[2],E.IframeEnd],[E.NoembedEnd[2],E.NoembedEnd],[E.Plaintext[2],E.Plaintext],[E.ScriptEnd[2],E.ScriptEnd],[E.TitleEnd[2],E.TitleEnd],[E.XmpEnd[2],E.XmpEnd]]);class Nu{cbs;state=f.Text;buffer="";sectionStart=0;index=0;entityStart=0;baseState=f.Text;isSpecial=!1;running=!0;offset=0;xmlMode;decodeEntities;recognizeSelfClosing;entityDecoder;constructor({xmlMode:t=!1,decodeEntities:n=!0,recognizeSelfClosing:i=t},r){this.cbs=r,this.xmlMode=t,this.decodeEntities=n,this.recognizeSelfClosing=i,this.entityDecoder=new Cu(t?Iu:ku,(s,a)=>this.emitCodePoint(s,a))}reset(){this.state=f.Text,this.buffer="",this.sectionStart=0,this.index=0,this.baseState=f.Text,this.isSpecial=!1,this.currentSequence=E.Empty,this.sequenceIndex=0,this.running=!0,this.offset=0}write(t){this.offset+=this.buffer.length,this.buffer=t,this.parse()}end(){this.running&&this.finish()}pause(){this.running=!1}resume(){this.running=!0,this.index<this.buffer.length+this.offset&&this.parse()}stateText(t){t===x.Lt||!this.decodeEntities&&this.fastForwardTo(x.Lt)?(this.index>this.sectionStart&&this.cbs.ontext(this.sectionStart,this.index),this.state=f.BeforeTagName,this.sectionStart=this.index):this.decodeEntities&&t===x.Amp&&this.startEntity()}currentSequence=E.Empty;sequenceIndex=0;enterTagBody(){this.currentSequence===E.Plaintext?(this.currentSequence=E.Empty,this.state=f.InPlainText):this.isSpecial?(this.state=f.InSpecialTag,this.sequenceIndex=0):this.state=f.Text}stateSpecialStartSequence(t){const n=t|32;if(this.sequenceIndex<this.currentSequence.length){if(n===this.currentSequence[this.sequenceIndex]){this.sequenceIndex++;return}if(this.sequenceIndex===3){if(this.currentSequence===E.ScriptEnd&&n===E.StyleEnd[3]){this.currentSequence=E.StyleEnd,this.sequenceIndex=4;return}if(this.currentSequence===E.TitleEnd&&n===E.TextareaEnd[3]){this.currentSequence=E.TextareaEnd,this.sequenceIndex=4;return}}else if(this.sequenceIndex===4&&this.currentSequence===E.NoembedEnd&&n===E.NoframesEnd[4]){this.currentSequence=E.NoframesEnd,this.sequenceIndex=5;return}}else if(Ne(t)){this.sequenceIndex=0,this.state=f.InTagName,this.stateInTagName(t);return}this.isSpecial=!1,this.currentSequence=E.Empty,this.sequenceIndex=0,this.state=f.InTagName,this.stateInTagName(t)}stateCDATASequence(t){t===E.Cdata[this.sequenceIndex]?++this.sequenceIndex===E.Cdata.length&&(this.state=f.InCommentLike,this.currentSequence=E.CdataEnd,this.sequenceIndex=0,this.sectionStart=this.index+1):(this.sequenceIndex=0,this.xmlMode?(this.state=f.InDeclaration,this.stateInDeclaration(t)):(this.state=f.InSpecialComment,this.stateInSpecialComment(t)))}fastForwardTo(t){for(;++this.index<this.buffer.length+this.offset;)if(this.buffer.charCodeAt(this.index-this.offset)===t)return!0;return this.index=this.buffer.length+this.offset-1,!1}emitComment(t){this.cbs.oncomment(this.sectionStart,this.index,t),this.sequenceIndex=0,this.sectionStart=this.index+1,this.state=f.Text}stateInCommentLike(t){!this.xmlMode&&this.currentSequence===E.CommentEnd&&this.sequenceIndex<=1&&this.index===this.sectionStart+this.sequenceIndex&&t===x.Gt?this.emitComment(this.sequenceIndex):this.currentSequence===E.CommentEnd&&this.sequenceIndex===2&&t===x.Gt?this.emitComment(2):this.currentSequence===E.CommentEnd&&this.sequenceIndex===this.currentSequence.length-1&&t!==x.Gt?this.sequenceIndex=+(t===x.Dash):t===this.currentSequence[this.sequenceIndex]?++this.sequenceIndex===this.currentSequence.length&&(this.currentSequence===E.CdataEnd?this.cbs.oncdata(this.sectionStart,this.index,2):this.cbs.oncomment(this.sectionStart,this.index,3),this.sequenceIndex=0,this.sectionStart=this.index+1,this.state=f.Text):this.sequenceIndex===0?this.fastForwardTo(this.currentSequence[0])&&(this.sequenceIndex=1):t!==this.currentSequence[this.sequenceIndex-1]&&(this.sequenceIndex=0)}isTagStartChar(t){return this.xmlMode?!Ne(t):_u(t)}stateInSpecialTag(t){if(this.sequenceIndex===this.currentSequence.length){if(Ne(t)){const n=this.index-this.currentSequence.length;if(this.sectionStart<n){const i=this.index;this.index=n,this.cbs.ontext(this.sectionStart,n),this.index=i}this.isSpecial=!1,this.sectionStart=n+2,this.stateInClosingTagName(t);return}this.sequenceIndex=0}(t|32)===this.currentSequence[this.sequenceIndex]?this.sequenceIndex+=1:this.sequenceIndex===0?this.currentSequence===E.TitleEnd||this.currentSequence===E.TextareaEnd?this.decodeEntities&&t===x.Amp&&this.startEntity():this.fastForwardTo(x.Lt)&&(this.sequenceIndex=1):this.sequenceIndex=+(t===x.Lt)}stateBeforeTagName(t){if(t===x.ExclamationMark)this.state=f.BeforeDeclaration,this.sectionStart=this.index+1;else if(t===x.Questionmark)this.xmlMode?(this.state=f.InProcessingInstruction,this.sequenceIndex=0,this.sectionStart=this.index+1):(this.state=f.InSpecialComment,this.sectionStart=this.index);else if(this.isTagStartChar(t)){this.sectionStart=this.index;const n=this.xmlMode||this.cbs.isInForeignContext?.()?void 0:Du.get(t|32);n===void 0?this.state=f.InTagName:(this.isSpecial=!0,this.currentSequence=n,this.sequenceIndex=3,this.state=f.SpecialStartSequence)}else t===x.Slash?this.state=f.BeforeClosingTagName:(this.state=f.Text,this.stateText(t))}stateInTagName(t){Ne(t)&&(this.cbs.onopentagname(this.sectionStart,this.index),this.sectionStart=-1,this.state=f.BeforeAttributeName,this.stateBeforeAttributeName(t))}stateBeforeClosingTagName(t){me(t)?this.xmlMode||(this.state=f.InSpecialComment,this.sectionStart=this.index):t===x.Gt?(this.state=f.Text,this.xmlMode||(this.sectionStart=this.index+1)):(this.state=this.isTagStartChar(t)?f.InClosingTagName:f.InSpecialComment,this.sectionStart=this.index)}stateInClosingTagName(t){Ne(t)&&(this.cbs.onclosetag(this.sectionStart,this.index),this.sectionStart=-1,this.state=f.AfterClosingTagName,this.stateAfterClosingTagName(t))}stateAfterClosingTagName(t){(t===x.Gt||this.fastForwardTo(x.Gt))&&(this.state=f.Text,this.sectionStart=this.index+1)}stateBeforeAttributeName(t){t===x.Gt?(this.cbs.onopentagend(this.index),this.enterTagBody(),this.sectionStart=this.index+1):t===x.Slash?this.state=f.InSelfClosingTag:me(t)||(this.state=f.InAttributeName,this.sectionStart=this.index)}stateInSelfClosingTag(t){if(t===x.Gt){if(this.cbs.onselfclosingtag(this.index),this.sectionStart=this.index+1,!this.recognizeSelfClosing){this.enterTagBody();return}this.state=f.Text,this.isSpecial=!1,this.currentSequence=E.Empty}else me(t)||(this.state=f.BeforeAttributeName,this.stateBeforeAttributeName(t))}stateInAttributeName(t){(t===x.Eq||Ne(t))&&(this.cbs.onattribname(this.sectionStart,this.index),this.sectionStart=this.index,this.state=f.AfterAttributeName,this.stateAfterAttributeName(t))}stateAfterAttributeName(t){t===x.Eq?this.state=f.BeforeAttributeValue:t===x.Slash||t===x.Gt?(this.cbs.onattribend($.NoValue,this.sectionStart),this.sectionStart=-1,this.state=f.BeforeAttributeName,this.stateBeforeAttributeName(t)):me(t)||(this.cbs.onattribend($.NoValue,this.sectionStart),this.state=f.InAttributeName,this.sectionStart=this.index)}stateBeforeAttributeValue(t){t===x.DoubleQuote?(this.state=f.InAttributeValueDq,this.sectionStart=this.index+1):t===x.SingleQuote?(this.state=f.InAttributeValueSq,this.sectionStart=this.index+1):me(t)||(this.sectionStart=this.index,this.state=f.InAttributeValueNq,this.stateInAttributeValueNoQuotes(t))}handleInAttributeValue(t,n){t===n||!this.decodeEntities&&this.fastForwardTo(n)?(this.cbs.onattribdata(this.sectionStart,this.index),this.sectionStart=-1,this.cbs.onattribend(n===x.DoubleQuote?$.Double:$.Single,this.index+1),this.state=f.BeforeAttributeName):this.decodeEntities&&t===x.Amp&&this.startEntity()}stateInAttributeValueDoubleQuotes(t){this.handleInAttributeValue(t,x.DoubleQuote)}stateInAttributeValueSingleQuotes(t){this.handleInAttributeValue(t,x.SingleQuote)}stateInAttributeValueNoQuotes(t){me(t)||t===x.Gt?(this.cbs.onattribdata(this.sectionStart,this.index),this.sectionStart=-1,this.cbs.onattribend($.Unquoted,this.index),this.state=f.BeforeAttributeName,this.stateBeforeAttributeName(t)):this.decodeEntities&&t===x.Amp&&this.startEntity()}stateBeforeDeclaration(t){t===x.OpeningSquareBracket?(this.state=f.CDATASequence,this.sequenceIndex=0):this.xmlMode?this.state=t===x.Dash?f.BeforeComment:f.InDeclaration:(t|32)===E.Doctype[0]?(this.state=f.DeclarationSequence,this.currentSequence=E.Doctype,this.sequenceIndex=1):t===x.Gt?(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=f.Text,this.sectionStart=this.index+1):t===x.Dash?this.state=f.BeforeComment:this.state=f.InSpecialComment}stateDeclarationSequence(t){this.sequenceIndex===this.currentSequence.length?(this.state=f.InDeclaration,this.stateInDeclaration(t)):(t|32)===this.currentSequence[this.sequenceIndex]?this.sequenceIndex+=1:t===x.Gt?(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=f.Text,this.sectionStart=this.index+1):this.state=f.InSpecialComment}stateInDeclaration(t){(t===x.Gt||this.fastForwardTo(x.Gt))&&(this.cbs.ondeclaration(this.sectionStart,this.index),this.state=f.Text,this.sectionStart=this.index+1)}stateInProcessingInstruction(t){t===x.Questionmark?this.sequenceIndex=1:t===x.Gt&&this.sequenceIndex===1?(this.cbs.onprocessinginstruction(this.sectionStart,this.index-1),this.sequenceIndex=0,this.state=f.Text,this.sectionStart=this.index+1):this.sequenceIndex=Number(this.fastForwardTo(x.Questionmark))}stateBeforeComment(t){t===x.Dash?(this.state=f.InCommentLike,this.currentSequence=E.CommentEnd,this.sequenceIndex=0,this.sectionStart=this.index+1):this.xmlMode?this.state=f.InDeclaration:t===x.Gt?(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=f.Text,this.sectionStart=this.index+1):this.state=f.InSpecialComment}stateInSpecialComment(t){(t===x.Gt||this.fastForwardTo(x.Gt))&&(this.cbs.oncomment(this.sectionStart,this.index,0),this.state=f.Text,this.sectionStart=this.index+1)}startEntity(){this.baseState=this.state,this.state=f.InEntity,this.entityStart=this.index,this.entityDecoder.startEntity(this.xmlMode?X.Strict:this.baseState===f.Text||this.baseState===f.InSpecialTag?X.Legacy:X.Attribute)}stateInEntity(){const t=this.index-this.offset,n=this.entityDecoder.write(this.buffer,t);if(n>=0)this.state=this.baseState,n===0&&(this.index-=1);else{if(t<this.buffer.length&&this.buffer.charCodeAt(t)===x.Amp){this.state=this.baseState,this.index-=1;return}this.index=this.offset+this.buffer.length-1}}cleanup(){this.running&&this.sectionStart!==this.index&&(this.state===f.Text||this.state===f.InPlainText||this.state===f.InSpecialTag&&this.sequenceIndex===0?(this.cbs.ontext(this.sectionStart,this.index),this.sectionStart=this.index):(this.state===f.InAttributeValueDq||this.state===f.InAttributeValueSq||this.state===f.InAttributeValueNq)&&(this.cbs.onattribdata(this.sectionStart,this.index),this.sectionStart=this.index))}shouldContinue(){return this.index<this.buffer.length+this.offset&&this.running}parse(){for(;this.shouldContinue();){const t=this.buffer.charCodeAt(this.index-this.offset);switch(this.state){case f.Text:{this.stateText(t);break}case f.InPlainText:{this.index=this.buffer.length+this.offset-1;break}case f.SpecialStartSequence:{this.stateSpecialStartSequence(t);break}case f.InSpecialTag:{this.stateInSpecialTag(t);break}case f.CDATASequence:{this.stateCDATASequence(t);break}case f.DeclarationSequence:{this.stateDeclarationSequence(t);break}case f.InAttributeValueDq:{this.stateInAttributeValueDoubleQuotes(t);break}case f.InAttributeName:{this.stateInAttributeName(t);break}case f.InCommentLike:{this.stateInCommentLike(t);break}case f.InSpecialComment:{this.stateInSpecialComment(t);break}case f.BeforeAttributeName:{this.stateBeforeAttributeName(t);break}case f.InTagName:{this.stateInTagName(t);break}case f.InClosingTagName:{this.stateInClosingTagName(t);break}case f.BeforeTagName:{this.stateBeforeTagName(t);break}case f.AfterAttributeName:{this.stateAfterAttributeName(t);break}case f.InAttributeValueSq:{this.stateInAttributeValueSingleQuotes(t);break}case f.BeforeAttributeValue:{this.stateBeforeAttributeValue(t);break}case f.BeforeClosingTagName:{this.stateBeforeClosingTagName(t);break}case f.AfterClosingTagName:{this.stateAfterClosingTagName(t);break}case f.InAttributeValueNq:{this.stateInAttributeValueNoQuotes(t);break}case f.InSelfClosingTag:{this.stateInSelfClosingTag(t);break}case f.InDeclaration:{this.stateInDeclaration(t);break}case f.BeforeDeclaration:{this.stateBeforeDeclaration(t);break}case f.BeforeComment:{this.stateBeforeComment(t);break}case f.InProcessingInstruction:{this.stateInProcessingInstruction(t);break}case f.InEntity:{this.stateInEntity();break}}this.index++}this.cleanup()}finish(){this.state===f.InEntity&&(this.entityDecoder.end(),this.state=this.baseState),this.handleTrailingData(),this.cbs.onend()}handleTrailingCommentLikeData(t){if(this.state!==f.InCommentLike)return!1;if(this.currentSequence===E.CdataEnd)if(this.xmlMode)this.sectionStart<t&&this.cbs.oncdata(this.sectionStart,t,0);else{const n=this.sectionStart-E.Cdata.length-1;this.cbs.oncomment(n,t,0)}else{const n=this.xmlMode?0:Math.min(this.sequenceIndex,E.CommentEnd.length-1);this.cbs.oncomment(this.sectionStart,t,n)}return!0}handleTrailingMarkupDeclaration(t){if(this.xmlMode)switch(this.state){case f.InSpecialComment:case f.BeforeComment:case f.CDATASequence:case f.DeclarationSequence:case f.InDeclaration:return this.cbs.ontext(this.sectionStart,t),!0;default:return!1}switch(this.state){case f.BeforeDeclaration:case f.InSpecialComment:case f.BeforeComment:case f.CDATASequence:return this.cbs.oncomment(this.sectionStart,t,0),!0;case f.DeclarationSequence:return this.sequenceIndex!==E.Doctype.length&&this.cbs.oncomment(this.sectionStart,t,0),!0;case f.InDeclaration:return!0;default:return!1}}handleTrailingData(){const t=this.buffer.length+this.offset;if(!(this.handleTrailingCommentLikeData(t)||this.handleTrailingMarkupDeclaration(t))&&!(this.sectionStart>=t))switch(this.state){case f.InTagName:case f.BeforeAttributeName:case f.BeforeAttributeValue:case f.AfterAttributeName:case f.InAttributeName:case f.InAttributeValueSq:case f.InAttributeValueDq:case f.InAttributeValueNq:case f.InClosingTagName:break;default:this.cbs.ontext(this.sectionStart,t)}}emitCodePoint(t,n){this.baseState!==f.Text&&this.baseState!==f.InSpecialTag?(this.sectionStart<this.entityStart&&this.cbs.onattribdata(this.sectionStart,this.entityStart),this.sectionStart=this.entityStart+n,this.index=this.sectionStart-1,this.cbs.onattribentity(t)):(this.sectionStart<this.entityStart&&this.cbs.ontext(this.sectionStart,this.entityStart),this.sectionStart=this.entityStart+n,this.index=this.sectionStart-1,this.cbs.ontextentity(t,this.sectionStart))}}const{fromCodePoint:xr}=String,Fe=new Set(["input","option","optgroup","select","button","datalist","textarea"]),O=new Set(["p"]),Ze=new Set(["h1","h2","h3","h4","h5","h6","p"]),Sr=new Set(["thead","tbody"]),Er=new Set(["dd","dt"]),Cr=new Set(["rt","rp"]),Fu=new Map([["tr",new Set(["tr","th","td"])],["th",new Set(["th"])],["td",new Set(["thead","th","td"])],["body",new Set(["head","link","script"])],["a",new Set(["a"])],["li",new Set(["li"])],["p",O],["h1",Ze],["h2",Ze],["h3",Ze],["h4",Ze],["h5",Ze],["h6",Ze],["select",Fe],["input",Fe],["output",Fe],["button",Fe],["datalist",Fe],["textarea",Fe],["option",new Set(["option"])],["optgroup",new Set(["optgroup","option"])],["dd",Er],["dt",Er],["address",O],["article",O],["aside",O],["blockquote",O],["details",O],["div",O],["dl",O],["fieldset",O],["figcaption",O],["figure",O],["footer",O],["form",O],["header",O],["hr",O],["main",O],["nav",O],["ol",O],["pre",O],["section",O],["table",O],["ul",O],["rt",Cr],["rp",Cr],["tbody",Sr],["tfoot",Sr]]),Br="doctype",Zu=new Set(["area","base","basefont","br","col","command","embed","frame","hr","img","input","isindex","keygen","link","meta","param","source","track","wbr"]),Ru=new Set(["math","svg"]),_r=new Set(["mi","mo","mn","ms","mtext","annotation-xml","foreignObject","desc","title"]),Dr=new Map([["altglyph","altGlyph"],["altglyphdef","altGlyphDef"],["altglyphitem","altGlyphItem"],["animatecolor","animateColor"],["animatemotion","animateMotion"],["animatetransform","animateTransform"],["clippath","clipPath"],["feblend","feBlend"],["fecolormatrix","feColorMatrix"],["fecomponenttransfer","feComponentTransfer"],["fecomposite","feComposite"],["feconvolvematrix","feConvolveMatrix"],["fediffuselighting","feDiffuseLighting"],["fedisplacementmap","feDisplacementMap"],["fedistantlight","feDistantLight"],["fedropshadow","feDropShadow"],["feflood","feFlood"],["fefunca","feFuncA"],["fefuncb","feFuncB"],["fefuncg","feFuncG"],["fefuncr","feFuncR"],["fegaussianblur","feGaussianBlur"],["feimage","feImage"],["femerge","feMerge"],["femergenode","feMergeNode"],["femorphology","feMorphology"],["feoffset","feOffset"],["fepointlight","fePointLight"],["fespecularlighting","feSpecularLighting"],["fespotlight","feSpotLight"],["fetile","feTile"],["feturbulence","feTurbulence"],["foreignobject","foreignObject"],["glyphref","glyphRef"],["lineargradient","linearGradient"],["radialgradient","radialGradient"],["textpath","textPath"]]);var se;(function(e){e[e.None=0]="None",e[e.Svg=1]="Svg",e[e.MathML=2]="MathML"})(se||(se={}));const Qu=/\s|\//;class Ou{options;startIndex=0;endIndex=0;openTagStart=0;tagname="";attribname="";attribvalue="";attribs=null;stack=[];foreignContext;cbs;lowerCaseTagNames;lowerCaseAttributeNames;recognizeSelfClosing;htmlMode;tokenizer;buffers=[];bufferOffset=0;writeIndex=0;ended=!1;constructor(t,n={}){this.options=n,this.cbs=t??{},this.htmlMode=!this.options.xmlMode,this.lowerCaseTagNames=n.lowerCaseTags??this.htmlMode,this.lowerCaseAttributeNames=n.lowerCaseAttributeNames??this.htmlMode,this.recognizeSelfClosing=n.recognizeSelfClosing??!this.htmlMode,this.tokenizer=new(n.Tokenizer??Nu)(this.options,this),this.foreignContext=[se.None],this.cbs.onparserinit?.(this)}ontext(t,n){const i=this.getSlice(t,n);this.endIndex=n-1,this.cbs.ontext?.(i),this.startIndex=n}ontextentity(t,n){this.endIndex=n-1,this.cbs.ontext?.(xr(t)),this.startIndex=n}isInForeignContext(){return this.foreignContext[0]!==se.None}isVoidElement(t){return this.htmlMode&&Zu.has(t)}readTagName(t,n){const i=this.lowerCaseTagNames?this.getSlice(t,n).toLowerCase():this.getSlice(t,n);if(!(this.lowerCaseTagNames&&this.htmlMode))return i;if(this.foreignContext[0]===se.Svg)return Dr.get(i)??i;if(this.foreignContext.length>1){const r=Dr.get(i);if(r!==void 0&&this.stack.includes(r))return r}return this.isInForeignContext()?i:i==="image"?"img":i}onopentagname(t,n){this.endIndex=n,this.emitOpenTag(this.readTagName(t,n))}emitOpenTag(t){if(this.openTagStart=this.startIndex,this.tagname=t,this.htmlMode&&t==="form"&&this.stack.includes("form")){this.tagname="";return}const n=this.htmlMode&&Fu.get(t);if(n)for(;this.stack.length>0&&n.has(this.stack[0]);)this.popElement(!0);this.isVoidElement(t)||(this.stack.unshift(t),this.htmlMode&&(t==="svg"?this.foreignContext.unshift(se.Svg):t==="math"?this.foreignContext.unshift(se.MathML):_r.has(t)&&this.foreignContext.unshift(se.None))),this.cbs.onopentagname?.(t),this.cbs.onopentag&&(this.attribs={})}endOpenTag(t){this.startIndex=this.openTagStart,this.attribs&&(this.cbs.onopentag?.(this.tagname,this.attribs,t),this.attribs=null),this.cbs.onclosetag&&this.isVoidElement(this.tagname)&&this.cbs.onclosetag(this.tagname,!0),this.tagname=""}onopentagend(t){this.endIndex=t,this.endOpenTag(!1),this.startIndex=t+1}onclosetag(t,n){this.endIndex=n;const i=this.readTagName(t,n);if(this.isVoidElement(i))this.htmlMode&&i==="br"&&(this.cbs.onopentagname?.("br"),this.cbs.onopentag?.("br",{},!0),this.cbs.onclosetag?.("br",!1));else{const r=this.stack.indexOf(i);if(r!==-1){for(let s=0;s<r;s++)this.popElement(!0);this.popElement(!1)}else this.htmlMode&&i==="p"&&(this.emitOpenTag("p"),this.closeCurrentTag(!0))}this.startIndex=n+1}onselfclosingtag(t){this.endIndex=t,this.recognizeSelfClosing||this.isInForeignContext()?(this.closeCurrentTag(!1),this.startIndex=t+1):this.onopentagend(t)}popElement(t){const n=this.stack.shift();this.htmlMode&&(Ru.has(n)||_r.has(n))&&this.foreignContext.shift(),this.cbs.onclosetag?.(n,t)}closeCurrentTag(t){const n=this.tagname;this.endOpenTag(t),this.stack[0]===n&&this.popElement(!t)}onattribname(t,n){this.startIndex=t;const i=this.getSlice(t,n);this.attribname=this.lowerCaseAttributeNames?i.toLowerCase():i}onattribdata(t,n){this.attribvalue+=this.getSlice(t,n)}onattribentity(t){this.attribvalue+=xr(t)}onattribend(t,n){this.endIndex=n,this.cbs.onattribute?.(this.attribname,this.attribvalue,t===$.Double?'"':t===$.Single?"'":t===$.NoValue?void 0:null),this.attribs&&!Object.hasOwn(this.attribs,this.attribname)&&(this.attribs[this.attribname]=this.attribvalue),this.attribvalue=""}getInstructionName(t){const n=t.search(Qu);let i=n<0?t:t.substr(0,n);return this.lowerCaseTagNames&&(i=i.toLowerCase()),i}ondeclaration(t,n){this.endIndex=n;const i=this.getSlice(t,n);if(this.cbs.onprocessinginstruction){const r=this.htmlMode?this.lowerCaseTagNames?Br:i.slice(0,Br.length):this.getInstructionName(i);this.cbs.onprocessinginstruction(`!${r}`,`!${i}`)}this.startIndex=n+1}onprocessinginstruction(t,n){this.endIndex=n;const i=this.getSlice(t,n);if(this.cbs.onprocessinginstruction){const r=this.getInstructionName(i);this.cbs.onprocessinginstruction(`?${r}`,`?${i}`)}this.startIndex=n+1}oncomment(t,n,i){this.endIndex=n,this.cbs.oncomment?.(this.getSlice(t,n-i)),this.cbs.oncommentend?.(),this.startIndex=n+1}oncdata(t,n,i){this.endIndex=n;const r=this.getSlice(t,n-i);!this.htmlMode||this.options.recognizeCDATA?(this.cbs.oncdatastart?.(),this.cbs.ontext?.(r),this.cbs.oncdataend?.()):this.isInForeignContext()?this.cbs.ontext?.(r):(this.cbs.oncomment?.(`[CDATA[${r}]]`),this.cbs.oncommentend?.()),this.startIndex=n+1}onend(){if(this.cbs.onclosetag){this.endIndex=this.startIndex;for(let t=0;t<this.stack.length;t++)this.cbs.onclosetag(this.stack[t],!0)}this.cbs.onend?.()}reset(){this.cbs.onreset?.(),this.tokenizer.reset(),this.tagname="",this.attribname="",this.attribvalue="",this.attribs=null,this.stack.length=0,this.startIndex=0,this.endIndex=0,this.cbs.onparserinit?.(this),this.buffers.length=0,this.foreignContext.length=0,this.foreignContext.unshift(se.None),this.bufferOffset=0,this.writeIndex=0,this.ended=!1}parseComplete(t){this.reset(),this.end(t)}getSlice(t,n){if(t===n)return"";for(;t-this.bufferOffset>=this.buffers[0].length;)this.shiftBuffer();let i=this.buffers[0].slice(t-this.bufferOffset,n-this.bufferOffset);for(;n-this.bufferOffset>this.buffers[0].length;)this.shiftBuffer(),i+=this.buffers[0].slice(0,n-this.bufferOffset);return i}shiftBuffer(){this.bufferOffset+=this.buffers[0].length,this.writeIndex--,this.buffers.shift()}write(t){if(this.ended){this.cbs.onerror?.(new Error(".write() after done!"));return}this.buffers.push(t),this.tokenizer.running&&(this.tokenizer.write(t),this.writeIndex++)}end(t){if(this.ended){this.cbs.onerror?.(new Error(".end() after done!"));return}t&&this.write(t),this.ended=!0,this.tokenizer.end()}pause(){this.tokenizer.pause()}resume(){for(this.tokenizer.resume();this.tokenizer.running&&this.writeIndex<this.buffers.length;)this.tokenizer.write(this.buffers[this.writeIndex++]);this.ended&&this.tokenizer.end()}}var _;(function(e){e.Root="root",e.Text="text",e.Directive="directive",e.Comment="comment",e.Script="script",e.Style="style",e.Tag="tag",e.CDATA="cdata",e.Doctype="doctype"})(_||(_={}));function Uu(e){return e.type===_.Tag||e.type===_.Script||e.type===_.Style}_.Root;const nn=_.Text;_.Directive,_.Comment;const Wu=_.Script,zu=_.Style,Tu=_.Tag;_.CDATA,_.Doctype;class Nr{parent=null;prev=null;next=null;startIndex=null;endIndex=null;get parentNode(){return this.parent}set parentNode(t){this.parent=t}get previousSibling(){return this.prev}set previousSibling(t){this.prev=t}get nextSibling(){return this.next}set nextSibling(t){this.next=t}cloneNode(t=!1){return Or(this,t)}}class rn extends Nr{data;constructor(t){super(),this.data=t}get nodeValue(){return this.data}set nodeValue(t){this.data=t}}class on extends rn{type=_.Text;get nodeType(){return 3}}class Fr extends rn{type=_.Comment;get nodeType(){return 8}}class Zr extends rn{type=_.Directive;name;constructor(t,n){super(n),this.name=t}get nodeType(){return 1}"x-name";"x-publicId";"x-systemId"}class an extends Nr{children;constructor(t){super(),this.children=t}get firstChild(){return this.children[0]??null}get lastChild(){return this.children.length>0?this.children[this.children.length-1]:null}get childNodes(){return this.children}set childNodes(t){this.children=t}}class Rr extends an{type=_.CDATA;get nodeType(){return 4}}class sn extends an{type=_.Root;get nodeType(){return 9}}class Qr extends an{name;attribs;type;constructor(t,n,i=[],r=t==="script"?_.Script:t==="style"?_.Style:_.Tag){super(i),this.name=t,this.attribs=n,this.type=r}get nodeType(){return 1}get tagName(){return this.name}set tagName(t){this.name=t}get attributes(){return Object.keys(this.attribs).map(t=>({name:t,value:this.attribs[t],namespace:this["x-attribsNamespace"]?.[t],prefix:this["x-attribsPrefix"]?.[t]}))}namespace;"x-attribsNamespace";"x-attribsPrefix"}function Ku(e){return Uu(e)}function Gu(e){return e.type===_.CDATA}function Mu(e){return e.type===_.Text}function Ju(e){return e.type===_.Comment}function Yu(e){return e.type===_.Directive}function Lu(e){return e.type===_.Root}function Or(e,t=!1){let n;if(Mu(e))n=new on(e.data);else if(Ju(e))n=new Fr(e.data);else if(Ku(e)){const i=t?cn(e.children):[],r=new Qr(e.name,{...e.attribs},i);for(const s of i)s.parent=r;e.namespace!=null&&(r.namespace=e.namespace),e["x-attribsNamespace"]&&(r["x-attribsNamespace"]={...e["x-attribsNamespace"]}),e["x-attribsPrefix"]&&(r["x-attribsPrefix"]={...e["x-attribsPrefix"]}),n=r}else if(Gu(e)){const i=t?cn(e.children):[],r=new Rr(i);for(const s of i)s.parent=r;n=r}else if(Lu(e)){const i=t?cn(e.children):[],r=new sn(i);for(const s of i)s.parent=r;e["x-mode"]&&(r["x-mode"]=e["x-mode"]),n=r}else if(Yu(e)){const i=new Zr(e.name,e.data);e["x-name"]!=null&&(i["x-name"]=e["x-name"],i["x-publicId"]=e["x-publicId"],i["x-systemId"]=e["x-systemId"]),n=i}else throw new Error(`Not implemented yet: ${e.type}`);return n.startIndex=e.startIndex,n.endIndex=e.endIndex,e.sourceCodeLocation!=null&&(n.sourceCodeLocation=e.sourceCodeLocation),n}function cn(e){const t=e.map(n=>Or(n,!0));for(let n=1;n<t.length;n++)t[n].prev=t[n-1],t[n-1].next=t[n];return t}const Ur={withStartIndices:!1,withEndIndices:!1,xmlMode:!1};class Pu{dom=[];root=new sn(this.dom);callback;options;elementCB;done=!1;tagStack=[this.root];lastNode=null;parser=null;constructor(t,n,i){typeof n=="function"&&(i=n,n=Ur),typeof t=="object"&&(n=t,t=void 0),this.callback=t??null,this.options=n??Ur,this.elementCB=i??null}onparserinit(t){this.parser=t}onreset(){this.dom=[],this.root=new sn(this.dom),this.done=!1,this.tagStack=[this.root],this.lastNode=null,this.parser=null}onend(){this.done||(this.done=!0,this.parser=null,this.handleCallback(null))}onerror(t){this.handleCallback(t)}onclosetag(){this.lastNode=null;const t=this.tagStack.pop();this.options.withEndIndices&&this.parser&&(t.endIndex=this.parser.endIndex),this.elementCB&&this.elementCB(t)}onopentag(t,n){const i=this.options.xmlMode?_.Tag:void 0,r=new Qr(t,n,void 0,i);this.addNode(r),this.tagStack.push(r)}ontext(t){const{lastNode:n}=this;if(n&&n.type===_.Text)n.data+=t,this.options.withEndIndices&&this.parser&&(n.endIndex=this.parser.endIndex);else{const i=new on(t);this.addNode(i),this.lastNode=i}}oncomment(t){if(this.lastNode&&this.lastNode.type===_.Comment){this.lastNode.data+=t;return}const n=new Fr(t);this.addNode(n),this.lastNode=n}oncommentend(){this.lastNode=null}oncdatastart(){const t=new on(""),n=new Rr([t]);this.addNode(n),t.parent=n,this.lastNode=t}oncdataend(){this.lastNode=null}onprocessinginstruction(t,n){const i=new Zr(t,n);this.addNode(i)}handleCallback(t){if(typeof this.callback=="function")this.callback(t,this.dom);else if(t)throw t}addNode(t){const n=this.tagStack[this.tagStack.length-1],i=n.children[n.children.length-1];this.options.withStartIndices&&this.parser&&(t.startIndex=this.parser.startIndex),this.options.withEndIndices&&this.parser&&(t.endIndex=this.parser.endIndex),n.children.push(t),i&&(t.prev=i,i.next=t),t.parent=n,this.lastNode=null}}function Hu(e,t){const n=new Pu(void 0,t);return new Ou(n,t).end(e),n.root}const ln=new Set(["script","style","template"]),Wr=new Set([Tu,Wu,zu]),qu=new Set(["p","pre","blockquote","li","dt","dd","tr","figure","img","svg","canvas","picture","fieldset","label"]),ju=new Set(["group","radiogroup"]),zr=["data-facts","data-followups"],Tr=`${ae}://${ji}/`,Kr=`${ae}://${Vi}/`;function Vu(e,t){if(qu.has(t))return!0;const n=e.attribs?.role?.trim().toLowerCase();return n!==void 0&&ju.has(n)}function Xu(e,t){return e==="src"&&t.startsWith(Tr)&&Xi(t.slice(Tr.length))?"picture":Pl("demo").includes(e)&&t.startsWith(Kr)&&$i(t.slice(Kr.length))?"recording":t.replace(/\s+/g," ").trim()}function An(e,t,n=!1){if(e.type===nn)return(e.data??"").replace(/\s+/g," ").trim();if(!Wr.has(e.type))return"";const i=e.name?.toLowerCase()??"";if(zr.some(c=>e.attribs?.[c]!==void 0)||!n&&ln.has(i))return"";const r=Object.entries(e.attribs??{}).map(([c,l])=>[c.toLowerCase(),Xu(c.toLowerCase(),l)]).sort(([c],[l])=>c<l?-1:c>l?1:0).map(([c,l])=>`${c}="${l}"`).join(" "),s=(e.children??[]).map(c=>An(c,t,n)).filter(Boolean);n&&!(e.children??[]).some(c=>c.type===nn&&(c.data??"").trim())&&s.sort();const a=s.join(" ");return`<${i}${r?` ${r}`:""}>${a}</${i}>`}function $u(e,t){const n=Hu(e,{decodeEntities:!0,withStartIndices:!0}),i=[],r=[],s=c=>c.type===nn?c.data??"":ln.has(c.name??"")?"":(c.children??[]).map(l=>s(l)).join(" "),a=(c,l)=>{for(const A of c){if(!Wr.has(A.type))continue;const m=A.name?.toLowerCase()??"";if(ln.has(m)||zr.some(y=>A.attribs?.[y]!==void 0))continue;const v=A.startIndex,I=/^h[1-6]$/.test(m)?Number(m[1]):0;if(I&&typeof v=="number"){const y=s(A).replace(/\s+/g," ").trim();for(;r.length&&r[r.length-1].level>=I;)r.pop();const B={start:v,label:y,path:JSON.stringify([...r.map(be=>be.area.label),y]),...A.attribs?.id||l?{stableId:A.attribs?.id||l}:{}};r.push({level:I,area:B}),i.push({start:v,key:An(A,t),heading:!0,area:B})}else Vu(A,m)&&typeof v=="number"?i.push({start:v,key:An(A,t),heading:!1,...r.at(-1)?{area:r.at(-1).area}:{}}):a(A.children??[],A.attribs?.id||l)}};return a(n.children),i}const eh=`/* Shared by the shell and frame documents; no geometry or close choreography. */
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
`,th=`/* Infinitary — color system. Dark ("deep space") is the default theme; light opts in via [data-theme="light"]. */
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
`,nh=`/* Infinitary — radii, shadows, glow, blur, motion. */
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
`,ih=`/* Infinitary webfonts - Space Grotesk (UI/display) + JetBrains Mono (data/code).
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
`,rh=`/* Infinitary — spacing scale (4px base). Generous whitespace is the default; density is the exception. */
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
`,oh=`/* Infinitary — typography. Space Grotesk for UI and display, JetBrains Mono for data, keybinds, code. */
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
`,ah=/url\(\s*['"]?\.\.\/assets\/fonts\/([A-Za-z0-9._-]+)['"]?\s*\)/g;function sh(e=ih){return e.replaceAll(ah,(t,n)=>`url(${fu(n)})`)}const ch=`
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
  /* The rows of a card listing several asks to one connection (INF-2993): each row is
     one call with a bar on its left and its Allow box on its right, ticked as the card
     comes; an unticked row loses its bar and is struck through, and a tally under the
     rows counts the ticked ones as boxes change. */
  .inf-asks { list-style: none; margin: var(--space-3) 0; padding: 0; counter-reset: inf-runs inf-out inf-all; display: grid; gap: var(--space-2); }
  .inf-ask { counter-increment: inf-runs inf-all; margin: 0; padding: var(--space-2) var(--space-3); border: 1px solid var(--line-1); border-left: 3px solid var(--ok); border-radius: var(--radius-m); background: var(--bg-1); transition: opacity var(--dur-med) ease, border-color var(--dur-med) ease; }
  .inf-ask:has(input:not(:checked)) { counter-increment: inf-out inf-all; border-left-color: var(--line-2); background: transparent; }
  .inf-ask-head { display: flex; align-items: center; gap: var(--space-2); min-width: 0; }
  .inf-ask-n { font-family: var(--font-mono); font-size: var(--text-xs); color: var(--fg-3); min-width: 1.2em; }
  .inf-ask-name { font-weight: 500; color: var(--fg-1); min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .inf-ask-joined { font-size: var(--text-xs); color: var(--accent); background: var(--accent-dim); border-radius: var(--radius-s); padding: 0 var(--space-1); white-space: nowrap; }
  .inf-ask-out { margin-left: auto; display: inline-flex; align-items: center; gap: var(--space-1); font-size: var(--text-sm); color: var(--fg-2); white-space: nowrap; cursor: pointer; }
  .inf-ask-input { box-sizing: border-box; width: 100%; max-width: none; margin: var(--space-2) 0 0; padding: var(--space-1) var(--space-2); background: var(--bg-0); border-radius: var(--radius-s); font-family: var(--font-mono); font-size: var(--text-sm); color: var(--fg-1); white-space: pre-wrap; overflow-wrap: anywhere; }
  dl.inf-ask-input { display: grid; grid-template-columns: auto minmax(0, 1fr); column-gap: var(--space-3); }
  .inf-ask-input dt { color: var(--fg-3); }
  .inf-ask-input dd { margin: 0; overflow-wrap: anywhere; }
  .inf-ask-why { margin: var(--space-1) 0 0; font-size: var(--text-sm); color: var(--fg-2); }
  .inf-ask:has(input:not(:checked)) :is(.inf-ask-name, .inf-ask-input, .inf-ask-why) { opacity: 0.45; text-decoration: line-through; text-decoration-color: var(--fg-3); }
  .inf-asks-tally { margin: 0; padding: 0 var(--space-1); font-size: var(--text-sm); color: var(--fg-2); }
  .inf-asks-tally::before { content: counter(inf-runs) attr(data-of) counter(inf-all) attr(data-ticked); white-space: pre; }
  .inf-asks-buttons { display: grid; grid-template-columns: max-content minmax(0, 1fr); gap: var(--space-1) var(--space-3); margin: 0 0 var(--space-2); font-size: var(--text-sm); }
  .inf-asks-buttons dt { color: var(--fg-1); font-weight: 500; }
  .inf-asks-buttons dd { margin: 0; color: var(--fg-2); }
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
`;let Gr;function lh(){return Gr??=[th,oh,rh,nh,eh,sh(),ch].join(`
`),Gr}function Ah(e){return/<[a-z][\s\S]*>/i.test(e)?e:uh(e)}function dh(e){return e.replaceAll("&","&amp;").replaceAll("<","&lt;").replaceAll(">","&gt;").replaceAll('"',"&quot;").replaceAll("'","&#39;")}function uh(e){return bu(e).map(n=>{const i=dh(n.value);return n.type==="url"&&yr(n.value)?`<a href="${i}">${i}</a>`:i}).join("").split(/\n{2,}/).map(n=>`<p>${n.replaceAll(`
`,"<br>")}</p>`).join("")}const hh=8;function fh(e,t=[]){const n=Ah(e);if(n!==e)return{html:n,marked:!1};const i=$u(e),r=i.length<=tt?i.map(m=>m.start):[],s=[...new Set([...t,...r])].sort((m,v)=>v-m);let a=n;const c=[];for(const m of s){const v=/^<[a-z][^\s/>]*/i.exec(a.slice(m,m+64));if(!v)continue;const I=m+v[0].length,y=c.length,B=t.includes(m);a=`${a.slice(0,I)}${r.includes(m)?` data-inf-target="${m}"`:""}${B?` data-inf-changed="${y}"`:""}${a.slice(I)}`,B&&c.push(y)}if(c.length===0)return{html:a,marked:!1};const l=c.map(m=>`[data-inf-changed="${m}"]{anchor-name:--fm-new-${m}}`).join(""),A=c.map(m=>`<i data-inf-bar="" style="position-anchor:--fm-new-${m}"></i>`).join("");return{html:`${a}<style>${l}</style><div data-inf-bars="" aria-hidden="true">${A}</div>`,marked:!0}}const ph=`
  /* HtmlCardBody owns the vertical inset outside this auto-sized viewport.
     flow-root keeps child margins in the measured body without padding. */
  body { padding-block: 0; display: flow-root; }
  :is(p, ul, ol, dl, blockquote, h1, h2, h3, h4, h5, h6, figcaption, summary) { max-width: 66ch; }
  /* A group's caption is its own line under the strip (flex-basis 100%): a
     narrower box would let it rise beside the thumbnails, so the line keeps
     the group's width and its text keeps the measure. */
  .inf-pictures > figcaption { max-width: none; padding-right: max(0px, calc(100% - 66ch)); }
`,mh=`
  body:has([data-inf-bars]) { padding-left: calc(var(--space-1) + ${hh}px); }
  [data-inf-bar] {
    position: absolute; left: calc(var(--space-1) - 2px); width: 2px;
    top: anchor(top); bottom: anchor(bottom);
    position-visibility: anchors-visible;
    border-radius: var(--radius-pill); background: var(--accent); pointer-events: none;
  }
`,gh=`
  [data-inf-inset] {
    float: right; clear: right; margin: 0;
    width: max(0px, calc(var(--inf-inset-width, 0px) - var(--space-1)));
    height: var(--inf-inset-height, 0px);
  }
  [data-inf-inset] ~ .inf-panel { display: flow-root; }
  [data-inf-inset] ~ :nth-child(n + 3 of :is(h1, h2, h3, h4, h5, h6, :has(:is(h1, h2, h3, h4, h5, h6)))) {
    clear: right;
  }
`;let Mr;function wh(){return Mr??=`${lh()}
${ph}
${mh}
${gh}
${bh}`,Mr}const bh=`
  [data-inf-revision-highlight] { background-color: var(--accent-dim); box-shadow: var(--focus-ring-inset); }
`,P=e=>window.webkit.messageHandlers.cardHost.postMessage(e);let ee,ge,we,At=[];const Jr=()=>document.hasFocus()&&navigator.userActivation.isActive;let vh=0;const dt=new Map,ce=e=>ee?.contentWindow?.postMessage({fm:2,...e},"*"),Yr=e=>new Error(e);window.addEventListener("message",e=>{if(!ee||e.source!==ee.contentWindow)return;const t=od.safeParse(e.data);if(!t.success)return;const n=t.data;if(n.type==="ready"){if(ge||!n.document)return;ge=n.document,P({type:"ready"}).catch(()=>{}),ce({type:"form",fill:Be.parse(we.fill??[]),readOnly:we.readOnly}),ce({type:"keys",pictures:!0,escape:!1}),ce({type:"width",width:we.width}),At.length>0&&ce({type:"tasks",keys:At}),ce({type:"initialize",document:ge,latePictures:!0});return}if(!(!ge||"document"in n&&n.document&&n.document!==ge))switch(n.type){case"answers":{const{questions:i,...r}=n,s=Qt.safeParse(i),a={...r,...s.success?{questions:s.data}:{questionsGap:"invalid"}};if(P({type:"answers",reading:a}).catch(()=>{}),n.seq!==void 0){const c=dt.get(n.seq);c&&(clearTimeout(c.timer),dt.delete(n.seq),c.resolve(a))}break}case"resize":ee.style.height=`${Math.max(48,Math.min(1e6,n.height))}px`,n.initialized&&P({type:"drawn",height:n.height}).catch(()=>{});break;case"pong":P({type:"pong",seq:n.seq}).catch(()=>{});break;case"request":{const i=ed.safeParse(n),r=(a,c)=>ce({type:"response",document:ge,id:n.id,...a?{ok:a,result:c}:{ok:a,error:{code:"refused",message:String(c)}}});if(!i.success||i.data.verb!=="action"||we.readOnly||!we.actions.includes(i.data.action)){r(!1,"This card cannot do that.");return}const s=i.data.value;if(s!==void 0&&new TextEncoder().encode(JSON.stringify(s)).length>YA){r(!1,"The answer is too large.");return}P({type:"action",id:i.data.action,value:s??null}).then(a=>r(!0,a),a=>r(!1,a));break}case"image":{if(!document.hasFocus()||!navigator.userActivation.isActive)return;const i=tr(n.index,n.pictures);i&&P({type:"image",...i}).catch(()=>{});break}case"demo":document.hasFocus()&&navigator.userActivation.isActive&&pd(we.body).has(n.src)&&tr(0,[n.poster])&&P({type:"demo",src:n.src,poster:n.poster,caption:n.caption,play:n.play}).catch(()=>{});break;case"link":Jr()&&yr(n.href)&&P({type:"link",href:n.href}).catch(()=>{});break;case"draft":Jr()&&P({type:"draft",text:n.text}).catch(()=>{});break;case"task":n.gesture==="open"&&At.includes(n.key)&&P({type:"task",key:n.key}).catch(()=>{});break;case"entry":P({type:"mac-only"}).catch(()=>{});break}}),window.phoneCard={async mount(e){we=e;const t=e.card&&rA(e.card)?oA(e.body):void 0,n=(e.marks??[]).map(l=>t&&l>t.at?l-t.facts.length:l);At=e.keys?.length?zA(e.body).filter(l=>e.keys.includes(l)):[],P({type:"mounted",facts:t?.facts??null,preview:tA(e.body)}).catch(()=>{});const i=fh(t?.body??e.body,n).html,r=new DOMParser().parseFromString(i,"text/html"),s=Array.from(r.querySelectorAll("script:not([src])"),l=>l.textContent??""),a=await P({type:"hash",scripts:s}),c=pu({csp:`${Gt(a)}; base-uri 'none'; form-action 'none'`,theme:e.theme,style:wh(),html:i});ee=window.document.createElement("iframe"),ee.title="Card body",ee.setAttribute("sandbox",gd),ee.style.cssText="display:block;width:100%;height:48px;border:0",ee.srcdoc=c,window.document.body.replaceChildren(ee)},collect(){if(!ge)return Promise.reject(Yr("This card is still drawing. Try again once it is ready."));const e=++vh;return new Promise((t,n)=>{const i=setTimeout(()=>{dt.delete(e),n(Yr("This card did not answer. Your choice was not sent."))},3e3);dt.set(e,{resolve:t,reject:n,timer:i}),ce({type:"collect",seq:e,focusUnpicked:!0})})},theme(e){ce({type:"theme",theme:e})},ping(e){ce({type:"ping",seq:e})}}})();
