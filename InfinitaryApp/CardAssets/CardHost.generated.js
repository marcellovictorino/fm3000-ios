(function() {
  "use strict";
  var _a$1;
  function $constructor(name, initializer2, params) {
    function init(inst, def) {
      if (!inst._zod) {
        Object.defineProperty(inst, "_zod", {
          value: {
            def,
            constr: _,
            traits: /* @__PURE__ */ new Set()
          },
          enumerable: false
        });
      }
      if (inst._zod.traits.has(name)) {
        return;
      }
      inst._zod.traits.add(name);
      initializer2(inst, def);
      const proto = _.prototype;
      const keys = Object.keys(proto);
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i];
        if (!(k in inst)) {
          inst[k] = proto[k].bind(inst);
        }
      }
    }
    const Parent = params?.Parent ?? Object;
    class Definition extends Parent {
    }
    Object.defineProperty(Definition, "name", { value: name });
    function _(def) {
      var _a2;
      const inst = params?.Parent ? new Definition() : this;
      init(inst, def);
      (_a2 = inst._zod).deferred ?? (_a2.deferred = []);
      for (const fn of inst._zod.deferred) {
        fn();
      }
      return inst;
    }
    Object.defineProperty(_, "init", { value: init });
    Object.defineProperty(_, Symbol.hasInstance, {
      value: (inst) => {
        if (params?.Parent && inst instanceof params.Parent)
          return true;
        return inst?._zod?.traits?.has(name);
      }
    });
    Object.defineProperty(_, "name", { value: name });
    return _;
  }
  class $ZodAsyncError extends Error {
    constructor() {
      super(`Encountered Promise during synchronous parse. Use .parseAsync() instead.`);
    }
  }
  class $ZodEncodeError extends Error {
    constructor(name) {
      super(`Encountered unidirectional transform during encode: ${name}`);
      this.name = "ZodEncodeError";
    }
  }
  (_a$1 = globalThis).__zod_globalConfig ?? (_a$1.__zod_globalConfig = {});
  const globalConfig = globalThis.__zod_globalConfig;
  function config(newConfig) {
    return globalConfig;
  }
  function getEnumValues(entries) {
    const numericValues = Object.values(entries).filter((v) => typeof v === "number");
    const values = Object.entries(entries).filter(([k, _]) => numericValues.indexOf(+k) === -1).map(([_, v]) => v);
    return values;
  }
  function jsonStringifyReplacer(_, value) {
    if (typeof value === "bigint")
      return value.toString();
    return value;
  }
  function cached$1(getter) {
    return {
      get value() {
        {
          const value = getter();
          Object.defineProperty(this, "value", { value });
          return value;
        }
      }
    };
  }
  function nullish(input2) {
    return input2 === null || input2 === void 0;
  }
  function cleanRegex(source) {
    const start = source.startsWith("^") ? 1 : 0;
    const end = source.endsWith("$") ? source.length - 1 : source.length;
    return source.slice(start, end);
  }
  function floatSafeRemainder(val, step) {
    const ratio = val / step;
    const roundedRatio = Math.round(ratio);
    const tolerance = Number.EPSILON * Math.max(Math.abs(ratio), 1);
    if (Math.abs(ratio - roundedRatio) < tolerance)
      return 0;
    return ratio - roundedRatio;
  }
  const EVALUATING = /* @__PURE__ */ Symbol("evaluating");
  function defineLazy(object2, key, getter) {
    let value = void 0;
    Object.defineProperty(object2, key, {
      get() {
        if (value === EVALUATING) {
          return void 0;
        }
        if (value === void 0) {
          value = EVALUATING;
          value = getter();
        }
        return value;
      },
      set(v) {
        Object.defineProperty(object2, key, {
          value: v
          // configurable: true,
        });
      },
      configurable: true
    });
  }
  function assignProp(target, prop, value) {
    Object.defineProperty(target, prop, {
      value,
      writable: true,
      enumerable: true,
      configurable: true
    });
  }
  function mergeDefs(...defs) {
    const mergedDescriptors = {};
    for (const def of defs) {
      const descriptors = Object.getOwnPropertyDescriptors(def);
      Object.assign(mergedDescriptors, descriptors);
    }
    return Object.defineProperties({}, mergedDescriptors);
  }
  function esc(str) {
    return JSON.stringify(str);
  }
  function slugify(input2) {
    return input2.toLowerCase().trim().replace(/[^\w\s-]/g, "").replace(/[\s_-]+/g, "-").replace(/^-+|-+$/g, "");
  }
  const captureStackTrace = "captureStackTrace" in Error ? Error.captureStackTrace : (..._args) => {
  };
  function isObject(data) {
    return typeof data === "object" && data !== null && !Array.isArray(data);
  }
  const allowsEval = /* @__PURE__ */ cached$1(() => {
    if (globalConfig.jitless) {
      return false;
    }
    if (typeof navigator !== "undefined" && navigator?.userAgent?.includes("Cloudflare")) {
      return false;
    }
    try {
      const F = Function;
      new F("");
      return true;
    } catch (_) {
      return false;
    }
  });
  function isPlainObject(o) {
    if (isObject(o) === false)
      return false;
    const ctor = o.constructor;
    if (ctor === void 0)
      return true;
    if (typeof ctor !== "function")
      return true;
    const prot = ctor.prototype;
    if (isObject(prot) === false)
      return false;
    if (Object.prototype.hasOwnProperty.call(prot, "isPrototypeOf") === false) {
      return false;
    }
    return true;
  }
  function shallowClone(o) {
    if (isPlainObject(o))
      return { ...o };
    if (Array.isArray(o))
      return [...o];
    if (o instanceof Map)
      return new Map(o);
    if (o instanceof Set)
      return new Set(o);
    return o;
  }
  const propertyKeyTypes = /* @__PURE__ */ new Set(["string", "number", "symbol"]);
  function escapeRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }
  function clone(inst, def, params) {
    const cl = new inst._zod.constr(def ?? inst._zod.def);
    if (!def || params?.parent)
      cl._zod.parent = inst;
    return cl;
  }
  function normalizeParams(_params) {
    const params = _params;
    if (!params)
      return {};
    if (typeof params === "string")
      return { error: () => params };
    if (params?.message !== void 0) {
      if (params?.error !== void 0)
        throw new Error("Cannot specify both `message` and `error` params");
      params.error = params.message;
    }
    delete params.message;
    if (typeof params.error === "string")
      return { ...params, error: () => params.error };
    return params;
  }
  function optionalKeys(shape) {
    return Object.keys(shape).filter((k) => {
      return shape[k]._zod.optin === "optional" && shape[k]._zod.optout === "optional";
    });
  }
  const NUMBER_FORMAT_RANGES = {
    safeint: [Number.MIN_SAFE_INTEGER, Number.MAX_SAFE_INTEGER],
    int32: [-2147483648, 2147483647],
    uint32: [0, 4294967295],
    float32: [-34028234663852886e22, 34028234663852886e22],
    float64: [-Number.MAX_VALUE, Number.MAX_VALUE]
  };
  function pick(schema, mask) {
    const currDef = schema._zod.def;
    const checks = currDef.checks;
    const hasChecks = checks && checks.length > 0;
    if (hasChecks) {
      throw new Error(".pick() cannot be used on object schemas containing refinements");
    }
    const def = mergeDefs(schema._zod.def, {
      get shape() {
        const newShape = {};
        for (const key in mask) {
          if (!(key in currDef.shape)) {
            throw new Error(`Unrecognized key: "${key}"`);
          }
          if (!mask[key])
            continue;
          newShape[key] = currDef.shape[key];
        }
        assignProp(this, "shape", newShape);
        return newShape;
      },
      checks: []
    });
    return clone(schema, def);
  }
  function omit(schema, mask) {
    const currDef = schema._zod.def;
    const checks = currDef.checks;
    const hasChecks = checks && checks.length > 0;
    if (hasChecks) {
      throw new Error(".omit() cannot be used on object schemas containing refinements");
    }
    const def = mergeDefs(schema._zod.def, {
      get shape() {
        const newShape = { ...schema._zod.def.shape };
        for (const key in mask) {
          if (!(key in currDef.shape)) {
            throw new Error(`Unrecognized key: "${key}"`);
          }
          if (!mask[key])
            continue;
          delete newShape[key];
        }
        assignProp(this, "shape", newShape);
        return newShape;
      },
      checks: []
    });
    return clone(schema, def);
  }
  function extend(schema, shape) {
    if (!isPlainObject(shape)) {
      throw new Error("Invalid input to extend: expected a plain object");
    }
    const checks = schema._zod.def.checks;
    const hasChecks = checks && checks.length > 0;
    if (hasChecks) {
      const existingShape = schema._zod.def.shape;
      for (const key in shape) {
        if (Object.getOwnPropertyDescriptor(existingShape, key) !== void 0) {
          throw new Error("Cannot overwrite keys on object schemas containing refinements. Use `.safeExtend()` instead.");
        }
      }
    }
    const def = mergeDefs(schema._zod.def, {
      get shape() {
        const _shape = { ...schema._zod.def.shape, ...shape };
        assignProp(this, "shape", _shape);
        return _shape;
      }
    });
    return clone(schema, def);
  }
  function safeExtend(schema, shape) {
    if (!isPlainObject(shape)) {
      throw new Error("Invalid input to safeExtend: expected a plain object");
    }
    const def = mergeDefs(schema._zod.def, {
      get shape() {
        const _shape = { ...schema._zod.def.shape, ...shape };
        assignProp(this, "shape", _shape);
        return _shape;
      }
    });
    return clone(schema, def);
  }
  function merge(a, b) {
    if (a._zod.def.checks?.length) {
      throw new Error(".merge() cannot be used on object schemas containing refinements. Use .safeExtend() instead.");
    }
    const def = mergeDefs(a._zod.def, {
      get shape() {
        const _shape = { ...a._zod.def.shape, ...b._zod.def.shape };
        assignProp(this, "shape", _shape);
        return _shape;
      },
      get catchall() {
        return b._zod.def.catchall;
      },
      checks: b._zod.def.checks ?? []
    });
    return clone(a, def);
  }
  function partial(Class, schema, mask) {
    const currDef = schema._zod.def;
    const checks = currDef.checks;
    const hasChecks = checks && checks.length > 0;
    if (hasChecks) {
      throw new Error(".partial() cannot be used on object schemas containing refinements");
    }
    const def = mergeDefs(schema._zod.def, {
      get shape() {
        const oldShape = schema._zod.def.shape;
        const shape = { ...oldShape };
        if (mask) {
          for (const key in mask) {
            if (!(key in oldShape)) {
              throw new Error(`Unrecognized key: "${key}"`);
            }
            if (!mask[key])
              continue;
            shape[key] = Class ? new Class({
              type: "optional",
              innerType: oldShape[key]
            }) : oldShape[key];
          }
        } else {
          for (const key in oldShape) {
            shape[key] = Class ? new Class({
              type: "optional",
              innerType: oldShape[key]
            }) : oldShape[key];
          }
        }
        assignProp(this, "shape", shape);
        return shape;
      },
      checks: []
    });
    return clone(schema, def);
  }
  function required(Class, schema, mask) {
    const def = mergeDefs(schema._zod.def, {
      get shape() {
        const oldShape = schema._zod.def.shape;
        const shape = { ...oldShape };
        if (mask) {
          for (const key in mask) {
            if (!(key in shape)) {
              throw new Error(`Unrecognized key: "${key}"`);
            }
            if (!mask[key])
              continue;
            shape[key] = new Class({
              type: "nonoptional",
              innerType: oldShape[key]
            });
          }
        } else {
          for (const key in oldShape) {
            shape[key] = new Class({
              type: "nonoptional",
              innerType: oldShape[key]
            });
          }
        }
        assignProp(this, "shape", shape);
        return shape;
      }
    });
    return clone(schema, def);
  }
  function aborted(x, startIndex = 0) {
    if (x.aborted === true)
      return true;
    for (let i = startIndex; i < x.issues.length; i++) {
      if (x.issues[i]?.continue !== true) {
        return true;
      }
    }
    return false;
  }
  function explicitlyAborted(x, startIndex = 0) {
    if (x.aborted === true)
      return true;
    for (let i = startIndex; i < x.issues.length; i++) {
      if (x.issues[i]?.continue === false) {
        return true;
      }
    }
    return false;
  }
  function prefixIssues(path, issues) {
    return issues.map((iss) => {
      var _a2;
      (_a2 = iss).path ?? (_a2.path = []);
      iss.path.unshift(path);
      return iss;
    });
  }
  function unwrapMessage(message) {
    return typeof message === "string" ? message : message?.message;
  }
  function finalizeIssue(iss, ctx, config2) {
    const message = iss.message ? iss.message : unwrapMessage(iss.inst?._zod.def?.error?.(iss)) ?? unwrapMessage(ctx?.error?.(iss)) ?? unwrapMessage(config2.customError?.(iss)) ?? unwrapMessage(config2.localeError?.(iss)) ?? "Invalid input";
    const { inst: _inst, continue: _continue, input: _input, ...rest } = iss;
    rest.path ?? (rest.path = []);
    rest.message = message;
    if (ctx?.reportInput) {
      rest.input = _input;
    }
    return rest;
  }
  function getLengthableOrigin(input2) {
    if (Array.isArray(input2))
      return "array";
    if (typeof input2 === "string")
      return "string";
    return "unknown";
  }
  function issue(...args) {
    const [iss, input2, inst] = args;
    if (typeof iss === "string") {
      return {
        message: iss,
        code: "custom",
        input: input2,
        inst
      };
    }
    return { ...iss };
  }
  const initializer$1 = (inst, def) => {
    inst.name = "$ZodError";
    Object.defineProperty(inst, "_zod", {
      value: inst._zod,
      enumerable: false
    });
    Object.defineProperty(inst, "issues", {
      value: def,
      enumerable: false
    });
    inst.message = JSON.stringify(def, jsonStringifyReplacer, 2);
    Object.defineProperty(inst, "toString", {
      value: () => inst.message,
      enumerable: false
    });
  };
  const $ZodError = $constructor("$ZodError", initializer$1);
  const $ZodRealError = $constructor("$ZodError", initializer$1, { Parent: Error });
  function flattenError(error, mapper = (issue2) => issue2.message) {
    const fieldErrors = {};
    const formErrors = [];
    for (const sub of error.issues) {
      if (sub.path.length > 0) {
        fieldErrors[sub.path[0]] = fieldErrors[sub.path[0]] || [];
        fieldErrors[sub.path[0]].push(mapper(sub));
      } else {
        formErrors.push(mapper(sub));
      }
    }
    return { formErrors, fieldErrors };
  }
  function formatError(error, mapper = (issue2) => issue2.message) {
    const fieldErrors = { _errors: [] };
    const processError = (error2, path = []) => {
      for (const issue2 of error2.issues) {
        if (issue2.code === "invalid_union" && issue2.errors.length) {
          issue2.errors.map((issues) => processError({ issues }, [...path, ...issue2.path]));
        } else if (issue2.code === "invalid_key") {
          processError({ issues: issue2.issues }, [...path, ...issue2.path]);
        } else if (issue2.code === "invalid_element") {
          processError({ issues: issue2.issues }, [...path, ...issue2.path]);
        } else {
          const fullpath = [...path, ...issue2.path];
          if (fullpath.length === 0) {
            fieldErrors._errors.push(mapper(issue2));
          } else {
            let curr = fieldErrors;
            let i = 0;
            while (i < fullpath.length) {
              const el = fullpath[i];
              const terminal = i === fullpath.length - 1;
              if (!terminal) {
                curr[el] = curr[el] || { _errors: [] };
              } else {
                curr[el] = curr[el] || { _errors: [] };
                curr[el]._errors.push(mapper(issue2));
              }
              curr = curr[el];
              i++;
            }
          }
        }
      }
    };
    processError(error);
    return fieldErrors;
  }
  const _parse = (_Err) => (schema, value, _ctx, _params) => {
    const ctx = _ctx ? { ..._ctx, async: false } : { async: false };
    const result = schema._zod.run({ value, issues: [] }, ctx);
    if (result instanceof Promise) {
      throw new $ZodAsyncError();
    }
    if (result.issues.length) {
      const e = new (_params?.Err ?? _Err)(result.issues.map((iss) => finalizeIssue(iss, ctx, config())));
      captureStackTrace(e, _params?.callee);
      throw e;
    }
    return result.value;
  };
  const _parseAsync = (_Err) => async (schema, value, _ctx, params) => {
    const ctx = _ctx ? { ..._ctx, async: true } : { async: true };
    let result = schema._zod.run({ value, issues: [] }, ctx);
    if (result instanceof Promise)
      result = await result;
    if (result.issues.length) {
      const e = new (params?.Err ?? _Err)(result.issues.map((iss) => finalizeIssue(iss, ctx, config())));
      captureStackTrace(e, params?.callee);
      throw e;
    }
    return result.value;
  };
  const _safeParse = (_Err) => (schema, value, _ctx) => {
    const ctx = _ctx ? { ..._ctx, async: false } : { async: false };
    const result = schema._zod.run({ value, issues: [] }, ctx);
    if (result instanceof Promise) {
      throw new $ZodAsyncError();
    }
    return result.issues.length ? {
      success: false,
      error: new (_Err ?? $ZodError)(result.issues.map((iss) => finalizeIssue(iss, ctx, config())))
    } : { success: true, data: result.value };
  };
  const safeParse$1 = /* @__PURE__ */ _safeParse($ZodRealError);
  const _safeParseAsync = (_Err) => async (schema, value, _ctx) => {
    const ctx = _ctx ? { ..._ctx, async: true } : { async: true };
    let result = schema._zod.run({ value, issues: [] }, ctx);
    if (result instanceof Promise)
      result = await result;
    return result.issues.length ? {
      success: false,
      error: new _Err(result.issues.map((iss) => finalizeIssue(iss, ctx, config())))
    } : { success: true, data: result.value };
  };
  const safeParseAsync$1 = /* @__PURE__ */ _safeParseAsync($ZodRealError);
  const _encode = (_Err) => (schema, value, _ctx) => {
    const ctx = _ctx ? { ..._ctx, direction: "backward" } : { direction: "backward" };
    return _parse(_Err)(schema, value, ctx);
  };
  const _decode = (_Err) => (schema, value, _ctx) => {
    return _parse(_Err)(schema, value, _ctx);
  };
  const _encodeAsync = (_Err) => async (schema, value, _ctx) => {
    const ctx = _ctx ? { ..._ctx, direction: "backward" } : { direction: "backward" };
    return _parseAsync(_Err)(schema, value, ctx);
  };
  const _decodeAsync = (_Err) => async (schema, value, _ctx) => {
    return _parseAsync(_Err)(schema, value, _ctx);
  };
  const _safeEncode = (_Err) => (schema, value, _ctx) => {
    const ctx = _ctx ? { ..._ctx, direction: "backward" } : { direction: "backward" };
    return _safeParse(_Err)(schema, value, ctx);
  };
  const _safeDecode = (_Err) => (schema, value, _ctx) => {
    return _safeParse(_Err)(schema, value, _ctx);
  };
  const _safeEncodeAsync = (_Err) => async (schema, value, _ctx) => {
    const ctx = _ctx ? { ..._ctx, direction: "backward" } : { direction: "backward" };
    return _safeParseAsync(_Err)(schema, value, ctx);
  };
  const _safeDecodeAsync = (_Err) => async (schema, value, _ctx) => {
    return _safeParseAsync(_Err)(schema, value, _ctx);
  };
  const cuid = /^[cC][0-9a-z]{6,}$/;
  const cuid2 = /^[0-9a-z]+$/;
  const ulid = /^[0-9A-HJKMNP-TV-Za-hjkmnp-tv-z]{26}$/;
  const xid = /^[0-9a-vA-V]{20}$/;
  const ksuid = /^[A-Za-z0-9]{27}$/;
  const nanoid = /^[a-zA-Z0-9_-]{21}$/;
  const duration$1 = /^P(?:(\d+W)|(?!.*W)(?=\d|T\d)(\d+Y)?(\d+M)?(\d+D)?(T(?=\d)(\d+H)?(\d+M)?(\d+([.,]\d+)?S)?)?)$/;
  const guid = /^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$/;
  const uuid = (version2) => {
    if (!version2)
      return /^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)$/;
    return new RegExp(`^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-${version2}[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})$`);
  };
  const email = /^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$/;
  const _emoji$1 = `^(\\p{Extended_Pictographic}|\\p{Emoji_Component})+$`;
  function emoji() {
    return new RegExp(_emoji$1, "u");
  }
  const ipv4 = /^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])$/;
  const ipv6 = /^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:))$/;
  const cidrv4 = /^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9][0-9]|[0-9])\/([0-9]|[1-2][0-9]|3[0-2])$/;
  const cidrv6 = /^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|::|([0-9a-fA-F]{1,4})?::([0-9a-fA-F]{1,4}:?){0,6})\/(12[0-8]|1[01][0-9]|[1-9]?[0-9])$/;
  const base64 = /^$|^(?:[0-9a-zA-Z+/]{4})*(?:(?:[0-9a-zA-Z+/]{2}==)|(?:[0-9a-zA-Z+/]{3}=))?$/;
  const base64url = /^[A-Za-z0-9_-]*$/;
  const httpProtocol = /^https?$/;
  const e164 = /^\+[1-9]\d{6,14}$/;
  const dateSource = `(?:(?:\\d\\d[2468][048]|\\d\\d[13579][26]|\\d\\d0[48]|[02468][048]00|[13579][26]00)-02-29|\\d{4}-(?:(?:0[13578]|1[02])-(?:0[1-9]|[12]\\d|3[01])|(?:0[469]|11)-(?:0[1-9]|[12]\\d|30)|(?:02)-(?:0[1-9]|1\\d|2[0-8])))`;
  const date$1 = /* @__PURE__ */ new RegExp(`^${dateSource}$`);
  function timeSource(args) {
    const hhmm = `(?:[01]\\d|2[0-3]):[0-5]\\d`;
    const regex = typeof args.precision === "number" ? args.precision === -1 ? `${hhmm}` : args.precision === 0 ? `${hhmm}:[0-5]\\d` : `${hhmm}:[0-5]\\d\\.\\d{${args.precision}}` : `${hhmm}(?::[0-5]\\d(?:\\.\\d+)?)?`;
    return regex;
  }
  function time$1(args) {
    return new RegExp(`^${timeSource(args)}$`);
  }
  function datetime$1(args) {
    const time2 = timeSource({ precision: args.precision });
    const opts = ["Z"];
    if (args.local)
      opts.push("");
    if (args.offset)
      opts.push(`([+-](?:[01]\\d|2[0-3]):[0-5]\\d)`);
    const timeRegex = `${time2}(?:${opts.join("|")})`;
    return new RegExp(`^${dateSource}T(?:${timeRegex})$`);
  }
  const string$1 = (params) => {
    const regex = params ? `[\\s\\S]{${params?.minimum ?? 0},${params?.maximum ?? ""}}` : `[\\s\\S]*`;
    return new RegExp(`^${regex}$`);
  };
  const integer = /^-?\d+$/;
  const number$1 = /^-?\d+(?:\.\d+)?$/;
  const boolean$1 = /^(?:true|false)$/i;
  const _null$2 = /^null$/i;
  const _undefined$2 = /^undefined$/i;
  const lowercase = /^[^A-Z]*$/;
  const uppercase = /^[^a-z]*$/;
  const $ZodCheck = /* @__PURE__ */ $constructor("$ZodCheck", (inst, def) => {
    var _a2;
    inst._zod ?? (inst._zod = {});
    inst._zod.def = def;
    (_a2 = inst._zod).onattach ?? (_a2.onattach = []);
  });
  const numericOriginMap = {
    number: "number",
    bigint: "bigint",
    object: "date"
  };
  const $ZodCheckLessThan = /* @__PURE__ */ $constructor("$ZodCheckLessThan", (inst, def) => {
    $ZodCheck.init(inst, def);
    const origin = numericOriginMap[typeof def.value];
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      const curr = (def.inclusive ? bag.maximum : bag.exclusiveMaximum) ?? Number.POSITIVE_INFINITY;
      if (def.value < curr) {
        if (def.inclusive)
          bag.maximum = def.value;
        else
          bag.exclusiveMaximum = def.value;
      }
    });
    inst._zod.check = (payload) => {
      if (def.inclusive ? payload.value <= def.value : payload.value < def.value) {
        return;
      }
      payload.issues.push({
        origin,
        code: "too_big",
        maximum: typeof def.value === "object" ? def.value.getTime() : def.value,
        input: payload.value,
        inclusive: def.inclusive,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckGreaterThan = /* @__PURE__ */ $constructor("$ZodCheckGreaterThan", (inst, def) => {
    $ZodCheck.init(inst, def);
    const origin = numericOriginMap[typeof def.value];
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      const curr = (def.inclusive ? bag.minimum : bag.exclusiveMinimum) ?? Number.NEGATIVE_INFINITY;
      if (def.value > curr) {
        if (def.inclusive)
          bag.minimum = def.value;
        else
          bag.exclusiveMinimum = def.value;
      }
    });
    inst._zod.check = (payload) => {
      if (def.inclusive ? payload.value >= def.value : payload.value > def.value) {
        return;
      }
      payload.issues.push({
        origin,
        code: "too_small",
        minimum: typeof def.value === "object" ? def.value.getTime() : def.value,
        input: payload.value,
        inclusive: def.inclusive,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckMultipleOf = /* @__PURE__ */ $constructor("$ZodCheckMultipleOf", (inst, def) => {
    $ZodCheck.init(inst, def);
    inst._zod.onattach.push((inst2) => {
      var _a2;
      (_a2 = inst2._zod.bag).multipleOf ?? (_a2.multipleOf = def.value);
    });
    inst._zod.check = (payload) => {
      if (typeof payload.value !== typeof def.value)
        throw new Error("Cannot mix number and bigint in multiple_of check.");
      const isMultiple = typeof payload.value === "bigint" ? payload.value % def.value === BigInt(0) : floatSafeRemainder(payload.value, def.value) === 0;
      if (isMultiple)
        return;
      payload.issues.push({
        origin: typeof payload.value,
        code: "not_multiple_of",
        divisor: def.value,
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckNumberFormat = /* @__PURE__ */ $constructor("$ZodCheckNumberFormat", (inst, def) => {
    $ZodCheck.init(inst, def);
    def.format = def.format || "float64";
    const isInt = def.format?.includes("int");
    const origin = isInt ? "int" : "number";
    const [minimum, maximum] = NUMBER_FORMAT_RANGES[def.format];
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      bag.format = def.format;
      bag.minimum = minimum;
      bag.maximum = maximum;
      if (isInt)
        bag.pattern = integer;
    });
    inst._zod.check = (payload) => {
      const input2 = payload.value;
      if (isInt) {
        if (!Number.isInteger(input2)) {
          payload.issues.push({
            expected: origin,
            format: def.format,
            code: "invalid_type",
            continue: false,
            input: input2,
            inst
          });
          return;
        }
        if (!Number.isSafeInteger(input2)) {
          if (input2 > 0) {
            payload.issues.push({
              input: input2,
              code: "too_big",
              maximum: Number.MAX_SAFE_INTEGER,
              note: "Integers must be within the safe integer range.",
              inst,
              origin,
              inclusive: true,
              continue: !def.abort
            });
          } else {
            payload.issues.push({
              input: input2,
              code: "too_small",
              minimum: Number.MIN_SAFE_INTEGER,
              note: "Integers must be within the safe integer range.",
              inst,
              origin,
              inclusive: true,
              continue: !def.abort
            });
          }
          return;
        }
      }
      if (input2 < minimum) {
        payload.issues.push({
          origin: "number",
          input: input2,
          code: "too_small",
          minimum,
          inclusive: true,
          inst,
          continue: !def.abort
        });
      }
      if (input2 > maximum) {
        payload.issues.push({
          origin: "number",
          input: input2,
          code: "too_big",
          maximum,
          inclusive: true,
          inst,
          continue: !def.abort
        });
      }
    };
  });
  const $ZodCheckMaxLength = /* @__PURE__ */ $constructor("$ZodCheckMaxLength", (inst, def) => {
    var _a2;
    $ZodCheck.init(inst, def);
    (_a2 = inst._zod.def).when ?? (_a2.when = (payload) => {
      const val = payload.value;
      return !nullish(val) && val.length !== void 0;
    });
    inst._zod.onattach.push((inst2) => {
      const curr = inst2._zod.bag.maximum ?? Number.POSITIVE_INFINITY;
      if (def.maximum < curr)
        inst2._zod.bag.maximum = def.maximum;
    });
    inst._zod.check = (payload) => {
      const input2 = payload.value;
      const length = input2.length;
      if (length <= def.maximum)
        return;
      const origin = getLengthableOrigin(input2);
      payload.issues.push({
        origin,
        code: "too_big",
        maximum: def.maximum,
        inclusive: true,
        input: input2,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckMinLength = /* @__PURE__ */ $constructor("$ZodCheckMinLength", (inst, def) => {
    var _a2;
    $ZodCheck.init(inst, def);
    (_a2 = inst._zod.def).when ?? (_a2.when = (payload) => {
      const val = payload.value;
      return !nullish(val) && val.length !== void 0;
    });
    inst._zod.onattach.push((inst2) => {
      const curr = inst2._zod.bag.minimum ?? Number.NEGATIVE_INFINITY;
      if (def.minimum > curr)
        inst2._zod.bag.minimum = def.minimum;
    });
    inst._zod.check = (payload) => {
      const input2 = payload.value;
      const length = input2.length;
      if (length >= def.minimum)
        return;
      const origin = getLengthableOrigin(input2);
      payload.issues.push({
        origin,
        code: "too_small",
        minimum: def.minimum,
        inclusive: true,
        input: input2,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckLengthEquals = /* @__PURE__ */ $constructor("$ZodCheckLengthEquals", (inst, def) => {
    var _a2;
    $ZodCheck.init(inst, def);
    (_a2 = inst._zod.def).when ?? (_a2.when = (payload) => {
      const val = payload.value;
      return !nullish(val) && val.length !== void 0;
    });
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      bag.minimum = def.length;
      bag.maximum = def.length;
      bag.length = def.length;
    });
    inst._zod.check = (payload) => {
      const input2 = payload.value;
      const length = input2.length;
      if (length === def.length)
        return;
      const origin = getLengthableOrigin(input2);
      const tooBig = length > def.length;
      payload.issues.push({
        origin,
        ...tooBig ? { code: "too_big", maximum: def.length } : { code: "too_small", minimum: def.length },
        inclusive: true,
        exact: true,
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckStringFormat = /* @__PURE__ */ $constructor("$ZodCheckStringFormat", (inst, def) => {
    var _a2, _b;
    $ZodCheck.init(inst, def);
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      bag.format = def.format;
      if (def.pattern) {
        bag.patterns ?? (bag.patterns = /* @__PURE__ */ new Set());
        bag.patterns.add(def.pattern);
      }
    });
    if (def.pattern)
      (_a2 = inst._zod).check ?? (_a2.check = (payload) => {
        def.pattern.lastIndex = 0;
        if (def.pattern.test(payload.value))
          return;
        payload.issues.push({
          origin: "string",
          code: "invalid_format",
          format: def.format,
          input: payload.value,
          ...def.pattern ? { pattern: def.pattern.toString() } : {},
          inst,
          continue: !def.abort
        });
      });
    else
      (_b = inst._zod).check ?? (_b.check = () => {
      });
  });
  const $ZodCheckRegex = /* @__PURE__ */ $constructor("$ZodCheckRegex", (inst, def) => {
    $ZodCheckStringFormat.init(inst, def);
    inst._zod.check = (payload) => {
      def.pattern.lastIndex = 0;
      if (def.pattern.test(payload.value))
        return;
      payload.issues.push({
        origin: "string",
        code: "invalid_format",
        format: "regex",
        input: payload.value,
        pattern: def.pattern.toString(),
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckLowerCase = /* @__PURE__ */ $constructor("$ZodCheckLowerCase", (inst, def) => {
    def.pattern ?? (def.pattern = lowercase);
    $ZodCheckStringFormat.init(inst, def);
  });
  const $ZodCheckUpperCase = /* @__PURE__ */ $constructor("$ZodCheckUpperCase", (inst, def) => {
    def.pattern ?? (def.pattern = uppercase);
    $ZodCheckStringFormat.init(inst, def);
  });
  const $ZodCheckIncludes = /* @__PURE__ */ $constructor("$ZodCheckIncludes", (inst, def) => {
    $ZodCheck.init(inst, def);
    const escapedRegex = escapeRegex(def.includes);
    const pattern = new RegExp(typeof def.position === "number" ? `^.{${def.position}}${escapedRegex}` : escapedRegex);
    def.pattern = pattern;
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      bag.patterns ?? (bag.patterns = /* @__PURE__ */ new Set());
      bag.patterns.add(pattern);
    });
    inst._zod.check = (payload) => {
      if (payload.value.includes(def.includes, def.position))
        return;
      payload.issues.push({
        origin: "string",
        code: "invalid_format",
        format: "includes",
        includes: def.includes,
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckStartsWith = /* @__PURE__ */ $constructor("$ZodCheckStartsWith", (inst, def) => {
    $ZodCheck.init(inst, def);
    const pattern = new RegExp(`^${escapeRegex(def.prefix)}.*`);
    def.pattern ?? (def.pattern = pattern);
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      bag.patterns ?? (bag.patterns = /* @__PURE__ */ new Set());
      bag.patterns.add(pattern);
    });
    inst._zod.check = (payload) => {
      if (payload.value.startsWith(def.prefix))
        return;
      payload.issues.push({
        origin: "string",
        code: "invalid_format",
        format: "starts_with",
        prefix: def.prefix,
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckEndsWith = /* @__PURE__ */ $constructor("$ZodCheckEndsWith", (inst, def) => {
    $ZodCheck.init(inst, def);
    const pattern = new RegExp(`.*${escapeRegex(def.suffix)}$`);
    def.pattern ?? (def.pattern = pattern);
    inst._zod.onattach.push((inst2) => {
      const bag = inst2._zod.bag;
      bag.patterns ?? (bag.patterns = /* @__PURE__ */ new Set());
      bag.patterns.add(pattern);
    });
    inst._zod.check = (payload) => {
      if (payload.value.endsWith(def.suffix))
        return;
      payload.issues.push({
        origin: "string",
        code: "invalid_format",
        format: "ends_with",
        suffix: def.suffix,
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodCheckOverwrite = /* @__PURE__ */ $constructor("$ZodCheckOverwrite", (inst, def) => {
    $ZodCheck.init(inst, def);
    inst._zod.check = (payload) => {
      payload.value = def.tx(payload.value);
    };
  });
  class Doc {
    constructor(args = []) {
      this.content = [];
      this.indent = 0;
      if (this)
        this.args = args;
    }
    indented(fn) {
      this.indent += 1;
      fn(this);
      this.indent -= 1;
    }
    write(arg) {
      if (typeof arg === "function") {
        arg(this, { execution: "sync" });
        arg(this, { execution: "async" });
        return;
      }
      const content = arg;
      const lines = content.split("\n").filter((x) => x);
      const minIndent = Math.min(...lines.map((x) => x.length - x.trimStart().length));
      const dedented = lines.map((x) => x.slice(minIndent)).map((x) => " ".repeat(this.indent * 2) + x);
      for (const line of dedented) {
        this.content.push(line);
      }
    }
    compile() {
      const F = Function;
      const args = this?.args;
      const content = this?.content ?? [``];
      const lines = [...content.map((x) => `  ${x}`)];
      return new F(...args, lines.join("\n"));
    }
  }
  const version = {
    major: 4,
    minor: 4,
    patch: 3
  };
  const $ZodType = /* @__PURE__ */ $constructor("$ZodType", (inst, def) => {
    var _a2;
    inst ?? (inst = {});
    inst._zod.def = def;
    inst._zod.bag = inst._zod.bag || {};
    inst._zod.version = version;
    const checks = [...inst._zod.def.checks ?? []];
    if (inst._zod.traits.has("$ZodCheck")) {
      checks.unshift(inst);
    }
    for (const ch of checks) {
      for (const fn of ch._zod.onattach) {
        fn(inst);
      }
    }
    if (checks.length === 0) {
      (_a2 = inst._zod).deferred ?? (_a2.deferred = []);
      inst._zod.deferred?.push(() => {
        inst._zod.run = inst._zod.parse;
      });
    } else {
      const runChecks = (payload, checks2, ctx) => {
        let isAborted = aborted(payload);
        let asyncResult;
        for (const ch of checks2) {
          if (ch._zod.def.when) {
            if (explicitlyAborted(payload))
              continue;
            const shouldRun = ch._zod.def.when(payload);
            if (!shouldRun)
              continue;
          } else if (isAborted) {
            continue;
          }
          const currLen = payload.issues.length;
          const _ = ch._zod.check(payload);
          if (_ instanceof Promise && ctx?.async === false) {
            throw new $ZodAsyncError();
          }
          if (asyncResult || _ instanceof Promise) {
            asyncResult = (asyncResult ?? Promise.resolve()).then(async () => {
              await _;
              const nextLen = payload.issues.length;
              if (nextLen === currLen)
                return;
              if (!isAborted)
                isAborted = aborted(payload, currLen);
            });
          } else {
            const nextLen = payload.issues.length;
            if (nextLen === currLen)
              continue;
            if (!isAborted)
              isAborted = aborted(payload, currLen);
          }
        }
        if (asyncResult) {
          return asyncResult.then(() => {
            return payload;
          });
        }
        return payload;
      };
      const handleCanaryResult = (canary, payload, ctx) => {
        if (aborted(canary)) {
          canary.aborted = true;
          return canary;
        }
        const checkResult = runChecks(payload, checks, ctx);
        if (checkResult instanceof Promise) {
          if (ctx.async === false)
            throw new $ZodAsyncError();
          return checkResult.then((checkResult2) => inst._zod.parse(checkResult2, ctx));
        }
        return inst._zod.parse(checkResult, ctx);
      };
      inst._zod.run = (payload, ctx) => {
        if (ctx.skipChecks) {
          return inst._zod.parse(payload, ctx);
        }
        if (ctx.direction === "backward") {
          const canary = inst._zod.parse({ value: payload.value, issues: [] }, { ...ctx, skipChecks: true });
          if (canary instanceof Promise) {
            return canary.then((canary2) => {
              return handleCanaryResult(canary2, payload, ctx);
            });
          }
          return handleCanaryResult(canary, payload, ctx);
        }
        const result = inst._zod.parse(payload, ctx);
        if (result instanceof Promise) {
          if (ctx.async === false)
            throw new $ZodAsyncError();
          return result.then((result2) => runChecks(result2, checks, ctx));
        }
        return runChecks(result, checks, ctx);
      };
    }
    defineLazy(inst, "~standard", () => ({
      validate: (value) => {
        try {
          const r = safeParse$1(inst, value);
          return r.success ? { value: r.data } : { issues: r.error?.issues };
        } catch (_) {
          return safeParseAsync$1(inst, value).then((r) => r.success ? { value: r.data } : { issues: r.error?.issues });
        }
      },
      vendor: "zod",
      version: 1
    }));
  });
  const $ZodString = /* @__PURE__ */ $constructor("$ZodString", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.pattern = [...inst?._zod.bag?.patterns ?? []].pop() ?? string$1(inst._zod.bag);
    inst._zod.parse = (payload, _) => {
      if (def.coerce)
        try {
          payload.value = String(payload.value);
        } catch (_2) {
        }
      if (typeof payload.value === "string")
        return payload;
      payload.issues.push({
        expected: "string",
        code: "invalid_type",
        input: payload.value,
        inst
      });
      return payload;
    };
  });
  const $ZodStringFormat = /* @__PURE__ */ $constructor("$ZodStringFormat", (inst, def) => {
    $ZodCheckStringFormat.init(inst, def);
    $ZodString.init(inst, def);
  });
  const $ZodGUID = /* @__PURE__ */ $constructor("$ZodGUID", (inst, def) => {
    def.pattern ?? (def.pattern = guid);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodUUID = /* @__PURE__ */ $constructor("$ZodUUID", (inst, def) => {
    if (def.version) {
      const versionMap = {
        v1: 1,
        v2: 2,
        v3: 3,
        v4: 4,
        v5: 5,
        v6: 6,
        v7: 7,
        v8: 8
      };
      const v = versionMap[def.version];
      if (v === void 0)
        throw new Error(`Invalid UUID version: "${def.version}"`);
      def.pattern ?? (def.pattern = uuid(v));
    } else
      def.pattern ?? (def.pattern = uuid());
    $ZodStringFormat.init(inst, def);
  });
  const $ZodEmail = /* @__PURE__ */ $constructor("$ZodEmail", (inst, def) => {
    def.pattern ?? (def.pattern = email);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodURL = /* @__PURE__ */ $constructor("$ZodURL", (inst, def) => {
    $ZodStringFormat.init(inst, def);
    inst._zod.check = (payload) => {
      try {
        const trimmed = payload.value.trim();
        if (!def.normalize && def.protocol?.source === httpProtocol.source) {
          if (!/^https?:\/\//i.test(trimmed)) {
            payload.issues.push({
              code: "invalid_format",
              format: "url",
              note: "Invalid URL format",
              input: payload.value,
              inst,
              continue: !def.abort
            });
            return;
          }
        }
        const url = new URL(trimmed);
        if (def.hostname) {
          def.hostname.lastIndex = 0;
          if (!def.hostname.test(url.hostname)) {
            payload.issues.push({
              code: "invalid_format",
              format: "url",
              note: "Invalid hostname",
              pattern: def.hostname.source,
              input: payload.value,
              inst,
              continue: !def.abort
            });
          }
        }
        if (def.protocol) {
          def.protocol.lastIndex = 0;
          if (!def.protocol.test(url.protocol.endsWith(":") ? url.protocol.slice(0, -1) : url.protocol)) {
            payload.issues.push({
              code: "invalid_format",
              format: "url",
              note: "Invalid protocol",
              pattern: def.protocol.source,
              input: payload.value,
              inst,
              continue: !def.abort
            });
          }
        }
        if (def.normalize) {
          payload.value = url.href;
        } else {
          payload.value = trimmed;
        }
        return;
      } catch (_) {
        payload.issues.push({
          code: "invalid_format",
          format: "url",
          input: payload.value,
          inst,
          continue: !def.abort
        });
      }
    };
  });
  const $ZodEmoji = /* @__PURE__ */ $constructor("$ZodEmoji", (inst, def) => {
    def.pattern ?? (def.pattern = emoji());
    $ZodStringFormat.init(inst, def);
  });
  const $ZodNanoID = /* @__PURE__ */ $constructor("$ZodNanoID", (inst, def) => {
    def.pattern ?? (def.pattern = nanoid);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodCUID = /* @__PURE__ */ $constructor("$ZodCUID", (inst, def) => {
    def.pattern ?? (def.pattern = cuid);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodCUID2 = /* @__PURE__ */ $constructor("$ZodCUID2", (inst, def) => {
    def.pattern ?? (def.pattern = cuid2);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodULID = /* @__PURE__ */ $constructor("$ZodULID", (inst, def) => {
    def.pattern ?? (def.pattern = ulid);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodXID = /* @__PURE__ */ $constructor("$ZodXID", (inst, def) => {
    def.pattern ?? (def.pattern = xid);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodKSUID = /* @__PURE__ */ $constructor("$ZodKSUID", (inst, def) => {
    def.pattern ?? (def.pattern = ksuid);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodISODateTime = /* @__PURE__ */ $constructor("$ZodISODateTime", (inst, def) => {
    def.pattern ?? (def.pattern = datetime$1(def));
    $ZodStringFormat.init(inst, def);
  });
  const $ZodISODate = /* @__PURE__ */ $constructor("$ZodISODate", (inst, def) => {
    def.pattern ?? (def.pattern = date$1);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodISOTime = /* @__PURE__ */ $constructor("$ZodISOTime", (inst, def) => {
    def.pattern ?? (def.pattern = time$1(def));
    $ZodStringFormat.init(inst, def);
  });
  const $ZodISODuration = /* @__PURE__ */ $constructor("$ZodISODuration", (inst, def) => {
    def.pattern ?? (def.pattern = duration$1);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodIPv4 = /* @__PURE__ */ $constructor("$ZodIPv4", (inst, def) => {
    def.pattern ?? (def.pattern = ipv4);
    $ZodStringFormat.init(inst, def);
    inst._zod.bag.format = `ipv4`;
  });
  const $ZodIPv6 = /* @__PURE__ */ $constructor("$ZodIPv6", (inst, def) => {
    def.pattern ?? (def.pattern = ipv6);
    $ZodStringFormat.init(inst, def);
    inst._zod.bag.format = `ipv6`;
    inst._zod.check = (payload) => {
      try {
        new URL(`http://[${payload.value}]`);
      } catch {
        payload.issues.push({
          code: "invalid_format",
          format: "ipv6",
          input: payload.value,
          inst,
          continue: !def.abort
        });
      }
    };
  });
  const $ZodCIDRv4 = /* @__PURE__ */ $constructor("$ZodCIDRv4", (inst, def) => {
    def.pattern ?? (def.pattern = cidrv4);
    $ZodStringFormat.init(inst, def);
  });
  const $ZodCIDRv6 = /* @__PURE__ */ $constructor("$ZodCIDRv6", (inst, def) => {
    def.pattern ?? (def.pattern = cidrv6);
    $ZodStringFormat.init(inst, def);
    inst._zod.check = (payload) => {
      const parts = payload.value.split("/");
      try {
        if (parts.length !== 2)
          throw new Error();
        const [address, prefix] = parts;
        if (!prefix)
          throw new Error();
        const prefixNum = Number(prefix);
        if (`${prefixNum}` !== prefix)
          throw new Error();
        if (prefixNum < 0 || prefixNum > 128)
          throw new Error();
        new URL(`http://[${address}]`);
      } catch {
        payload.issues.push({
          code: "invalid_format",
          format: "cidrv6",
          input: payload.value,
          inst,
          continue: !def.abort
        });
      }
    };
  });
  function isValidBase64(data) {
    if (data === "")
      return true;
    if (/\s/.test(data))
      return false;
    if (data.length % 4 !== 0)
      return false;
    try {
      atob(data);
      return true;
    } catch {
      return false;
    }
  }
  const $ZodBase64 = /* @__PURE__ */ $constructor("$ZodBase64", (inst, def) => {
    def.pattern ?? (def.pattern = base64);
    $ZodStringFormat.init(inst, def);
    inst._zod.bag.contentEncoding = "base64";
    inst._zod.check = (payload) => {
      if (isValidBase64(payload.value))
        return;
      payload.issues.push({
        code: "invalid_format",
        format: "base64",
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  function isValidBase64URL(data) {
    if (!base64url.test(data))
      return false;
    const base642 = data.replace(/[-_]/g, (c) => c === "-" ? "+" : "/");
    const padded = base642.padEnd(Math.ceil(base642.length / 4) * 4, "=");
    return isValidBase64(padded);
  }
  const $ZodBase64URL = /* @__PURE__ */ $constructor("$ZodBase64URL", (inst, def) => {
    def.pattern ?? (def.pattern = base64url);
    $ZodStringFormat.init(inst, def);
    inst._zod.bag.contentEncoding = "base64url";
    inst._zod.check = (payload) => {
      if (isValidBase64URL(payload.value))
        return;
      payload.issues.push({
        code: "invalid_format",
        format: "base64url",
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodE164 = /* @__PURE__ */ $constructor("$ZodE164", (inst, def) => {
    def.pattern ?? (def.pattern = e164);
    $ZodStringFormat.init(inst, def);
  });
  function isValidJWT(token, algorithm = null) {
    try {
      const tokensParts = token.split(".");
      if (tokensParts.length !== 3)
        return false;
      const [header] = tokensParts;
      if (!header)
        return false;
      const parsedHeader = JSON.parse(atob(header));
      if ("typ" in parsedHeader && parsedHeader?.typ !== "JWT")
        return false;
      if (!parsedHeader.alg)
        return false;
      if (algorithm && (!("alg" in parsedHeader) || parsedHeader.alg !== algorithm))
        return false;
      return true;
    } catch {
      return false;
    }
  }
  const $ZodJWT = /* @__PURE__ */ $constructor("$ZodJWT", (inst, def) => {
    $ZodStringFormat.init(inst, def);
    inst._zod.check = (payload) => {
      if (isValidJWT(payload.value, def.alg))
        return;
      payload.issues.push({
        code: "invalid_format",
        format: "jwt",
        input: payload.value,
        inst,
        continue: !def.abort
      });
    };
  });
  const $ZodNumber = /* @__PURE__ */ $constructor("$ZodNumber", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.pattern = inst._zod.bag.pattern ?? number$1;
    inst._zod.parse = (payload, _ctx) => {
      if (def.coerce)
        try {
          payload.value = Number(payload.value);
        } catch (_) {
        }
      const input2 = payload.value;
      if (typeof input2 === "number" && !Number.isNaN(input2) && Number.isFinite(input2)) {
        return payload;
      }
      const received = typeof input2 === "number" ? Number.isNaN(input2) ? "NaN" : !Number.isFinite(input2) ? "Infinity" : void 0 : void 0;
      payload.issues.push({
        expected: "number",
        code: "invalid_type",
        input: input2,
        inst,
        ...received ? { received } : {}
      });
      return payload;
    };
  });
  const $ZodNumberFormat = /* @__PURE__ */ $constructor("$ZodNumberFormat", (inst, def) => {
    $ZodCheckNumberFormat.init(inst, def);
    $ZodNumber.init(inst, def);
  });
  const $ZodBoolean = /* @__PURE__ */ $constructor("$ZodBoolean", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.pattern = boolean$1;
    inst._zod.parse = (payload, _ctx) => {
      if (def.coerce)
        try {
          payload.value = Boolean(payload.value);
        } catch (_) {
        }
      const input2 = payload.value;
      if (typeof input2 === "boolean")
        return payload;
      payload.issues.push({
        expected: "boolean",
        code: "invalid_type",
        input: input2,
        inst
      });
      return payload;
    };
  });
  const $ZodUndefined = /* @__PURE__ */ $constructor("$ZodUndefined", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.pattern = _undefined$2;
    inst._zod.values = /* @__PURE__ */ new Set([void 0]);
    inst._zod.parse = (payload, _ctx) => {
      const input2 = payload.value;
      if (typeof input2 === "undefined")
        return payload;
      payload.issues.push({
        expected: "undefined",
        code: "invalid_type",
        input: input2,
        inst
      });
      return payload;
    };
  });
  const $ZodNull = /* @__PURE__ */ $constructor("$ZodNull", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.pattern = _null$2;
    inst._zod.values = /* @__PURE__ */ new Set([null]);
    inst._zod.parse = (payload, _ctx) => {
      const input2 = payload.value;
      if (input2 === null)
        return payload;
      payload.issues.push({
        expected: "null",
        code: "invalid_type",
        input: input2,
        inst
      });
      return payload;
    };
  });
  const $ZodUnknown = /* @__PURE__ */ $constructor("$ZodUnknown", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.parse = (payload) => payload;
  });
  const $ZodNever = /* @__PURE__ */ $constructor("$ZodNever", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.parse = (payload, _ctx) => {
      payload.issues.push({
        expected: "never",
        code: "invalid_type",
        input: payload.value,
        inst
      });
      return payload;
    };
  });
  function handleArrayResult(result, final, index) {
    if (result.issues.length) {
      final.issues.push(...prefixIssues(index, result.issues));
    }
    final.value[index] = result.value;
  }
  const $ZodArray = /* @__PURE__ */ $constructor("$ZodArray", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.parse = (payload, ctx) => {
      const input2 = payload.value;
      if (!Array.isArray(input2)) {
        payload.issues.push({
          expected: "array",
          code: "invalid_type",
          input: input2,
          inst
        });
        return payload;
      }
      payload.value = Array(input2.length);
      const proms = [];
      for (let i = 0; i < input2.length; i++) {
        const item = input2[i];
        const result = def.element._zod.run({
          value: item,
          issues: []
        }, ctx);
        if (result instanceof Promise) {
          proms.push(result.then((result2) => handleArrayResult(result2, payload, i)));
        } else {
          handleArrayResult(result, payload, i);
        }
      }
      if (proms.length) {
        return Promise.all(proms).then(() => payload);
      }
      return payload;
    };
  });
  function handlePropertyResult(result, final, key, input2, isOptionalIn, isOptionalOut) {
    const isPresent = key in input2;
    if (result.issues.length) {
      if (isOptionalIn && isOptionalOut && !isPresent) {
        return;
      }
      final.issues.push(...prefixIssues(key, result.issues));
    }
    if (!isPresent && !isOptionalIn) {
      if (!result.issues.length) {
        final.issues.push({
          code: "invalid_type",
          expected: "nonoptional",
          input: void 0,
          path: [key]
        });
      }
      return;
    }
    if (result.value === void 0) {
      if (isPresent) {
        final.value[key] = void 0;
      }
    } else {
      final.value[key] = result.value;
    }
  }
  function normalizeDef(def) {
    const keys = Object.keys(def.shape);
    for (const k of keys) {
      if (!def.shape?.[k]?._zod?.traits?.has("$ZodType")) {
        throw new Error(`Invalid element at key "${k}": expected a Zod schema`);
      }
    }
    const okeys = optionalKeys(def.shape);
    return {
      ...def,
      keys,
      keySet: new Set(keys),
      numKeys: keys.length,
      optionalKeys: new Set(okeys)
    };
  }
  function handleCatchall(proms, input2, payload, ctx, def, inst) {
    const unrecognized = [];
    const keySet = def.keySet;
    const _catchall = def.catchall._zod;
    const t = _catchall.def.type;
    const isOptionalIn = _catchall.optin === "optional";
    const isOptionalOut = _catchall.optout === "optional";
    for (const key in input2) {
      if (key === "__proto__")
        continue;
      if (keySet.has(key))
        continue;
      if (t === "never") {
        unrecognized.push(key);
        continue;
      }
      const r = _catchall.run({ value: input2[key], issues: [] }, ctx);
      if (r instanceof Promise) {
        proms.push(r.then((r2) => handlePropertyResult(r2, payload, key, input2, isOptionalIn, isOptionalOut)));
      } else {
        handlePropertyResult(r, payload, key, input2, isOptionalIn, isOptionalOut);
      }
    }
    if (unrecognized.length) {
      payload.issues.push({
        code: "unrecognized_keys",
        keys: unrecognized,
        input: input2,
        inst
      });
    }
    if (!proms.length)
      return payload;
    return Promise.all(proms).then(() => {
      return payload;
    });
  }
  const $ZodObject = /* @__PURE__ */ $constructor("$ZodObject", (inst, def) => {
    $ZodType.init(inst, def);
    const desc = Object.getOwnPropertyDescriptor(def, "shape");
    if (!desc?.get) {
      const sh = def.shape;
      Object.defineProperty(def, "shape", {
        get: () => {
          const newSh = { ...sh };
          Object.defineProperty(def, "shape", {
            value: newSh
          });
          return newSh;
        }
      });
    }
    const _normalized = cached$1(() => normalizeDef(def));
    defineLazy(inst._zod, "propValues", () => {
      const shape = def.shape;
      const propValues = {};
      for (const key in shape) {
        const field = shape[key]._zod;
        if (field.values) {
          propValues[key] ?? (propValues[key] = /* @__PURE__ */ new Set());
          for (const v of field.values)
            propValues[key].add(v);
        }
      }
      return propValues;
    });
    const isObject$1 = isObject;
    const catchall = def.catchall;
    let value;
    inst._zod.parse = (payload, ctx) => {
      value ?? (value = _normalized.value);
      const input2 = payload.value;
      if (!isObject$1(input2)) {
        payload.issues.push({
          expected: "object",
          code: "invalid_type",
          input: input2,
          inst
        });
        return payload;
      }
      payload.value = {};
      const proms = [];
      const shape = value.shape;
      for (const key of value.keys) {
        const el = shape[key];
        const isOptionalIn = el._zod.optin === "optional";
        const isOptionalOut = el._zod.optout === "optional";
        const r = el._zod.run({ value: input2[key], issues: [] }, ctx);
        if (r instanceof Promise) {
          proms.push(r.then((r2) => handlePropertyResult(r2, payload, key, input2, isOptionalIn, isOptionalOut)));
        } else {
          handlePropertyResult(r, payload, key, input2, isOptionalIn, isOptionalOut);
        }
      }
      if (!catchall) {
        return proms.length ? Promise.all(proms).then(() => payload) : payload;
      }
      return handleCatchall(proms, input2, payload, ctx, _normalized.value, inst);
    };
  });
  const $ZodObjectJIT = /* @__PURE__ */ $constructor("$ZodObjectJIT", (inst, def) => {
    $ZodObject.init(inst, def);
    const superParse = inst._zod.parse;
    const _normalized = cached$1(() => normalizeDef(def));
    const generateFastpass = (shape) => {
      const doc = new Doc(["shape", "payload", "ctx"]);
      const normalized = _normalized.value;
      const parseStr = (key) => {
        const k = esc(key);
        return `shape[${k}]._zod.run({ value: input[${k}], issues: [] }, ctx)`;
      };
      doc.write(`const input = payload.value;`);
      const ids = /* @__PURE__ */ Object.create(null);
      let counter = 0;
      for (const key of normalized.keys) {
        ids[key] = `key_${counter++}`;
      }
      doc.write(`const newResult = {};`);
      for (const key of normalized.keys) {
        const id = ids[key];
        const k = esc(key);
        const schema = shape[key];
        const isOptionalIn = schema?._zod?.optin === "optional";
        const isOptionalOut = schema?._zod?.optout === "optional";
        doc.write(`const ${id} = ${parseStr(key)};`);
        if (isOptionalIn && isOptionalOut) {
          doc.write(`
        if (${id}.issues.length) {
          if (${k} in input) {
            payload.issues = payload.issues.concat(${id}.issues.map(iss => ({
              ...iss,
              path: iss.path ? [${k}, ...iss.path] : [${k}]
            })));
          }
        }
        
        if (${id}.value === undefined) {
          if (${k} in input) {
            newResult[${k}] = undefined;
          }
        } else {
          newResult[${k}] = ${id}.value;
        }
        
      `);
        } else if (!isOptionalIn) {
          doc.write(`
        const ${id}_present = ${k} in input;
        if (${id}.issues.length) {
          payload.issues = payload.issues.concat(${id}.issues.map(iss => ({
            ...iss,
            path: iss.path ? [${k}, ...iss.path] : [${k}]
          })));
        }
        if (!${id}_present && !${id}.issues.length) {
          payload.issues.push({
            code: "invalid_type",
            expected: "nonoptional",
            input: undefined,
            path: [${k}]
          });
        }

        if (${id}_present) {
          if (${id}.value === undefined) {
            newResult[${k}] = undefined;
          } else {
            newResult[${k}] = ${id}.value;
          }
        }

      `);
        } else {
          doc.write(`
        if (${id}.issues.length) {
          payload.issues = payload.issues.concat(${id}.issues.map(iss => ({
            ...iss,
            path: iss.path ? [${k}, ...iss.path] : [${k}]
          })));
        }
        
        if (${id}.value === undefined) {
          if (${k} in input) {
            newResult[${k}] = undefined;
          }
        } else {
          newResult[${k}] = ${id}.value;
        }
        
      `);
        }
      }
      doc.write(`payload.value = newResult;`);
      doc.write(`return payload;`);
      const fn = doc.compile();
      return (payload, ctx) => fn(shape, payload, ctx);
    };
    let fastpass;
    const isObject$1 = isObject;
    const jit = !globalConfig.jitless;
    const allowsEval$1 = allowsEval;
    const fastEnabled = jit && allowsEval$1.value;
    const catchall = def.catchall;
    let value;
    inst._zod.parse = (payload, ctx) => {
      value ?? (value = _normalized.value);
      const input2 = payload.value;
      if (!isObject$1(input2)) {
        payload.issues.push({
          expected: "object",
          code: "invalid_type",
          input: input2,
          inst
        });
        return payload;
      }
      if (jit && fastEnabled && ctx?.async === false && ctx.jitless !== true) {
        if (!fastpass)
          fastpass = generateFastpass(def.shape);
        payload = fastpass(payload, ctx);
        if (!catchall)
          return payload;
        return handleCatchall([], input2, payload, ctx, value, inst);
      }
      return superParse(payload, ctx);
    };
  });
  function handleUnionResults(results, final, inst, ctx) {
    for (const result of results) {
      if (result.issues.length === 0) {
        final.value = result.value;
        return final;
      }
    }
    const nonaborted = results.filter((r) => !aborted(r));
    if (nonaborted.length === 1) {
      final.value = nonaborted[0].value;
      return nonaborted[0];
    }
    final.issues.push({
      code: "invalid_union",
      input: final.value,
      inst,
      errors: results.map((result) => result.issues.map((iss) => finalizeIssue(iss, ctx, config())))
    });
    return final;
  }
  const $ZodUnion = /* @__PURE__ */ $constructor("$ZodUnion", (inst, def) => {
    $ZodType.init(inst, def);
    defineLazy(inst._zod, "optin", () => def.options.some((o) => o._zod.optin === "optional") ? "optional" : void 0);
    defineLazy(inst._zod, "optout", () => def.options.some((o) => o._zod.optout === "optional") ? "optional" : void 0);
    defineLazy(inst._zod, "values", () => {
      if (def.options.every((o) => o._zod.values)) {
        return new Set(def.options.flatMap((option) => Array.from(option._zod.values)));
      }
      return void 0;
    });
    defineLazy(inst._zod, "pattern", () => {
      if (def.options.every((o) => o._zod.pattern)) {
        const patterns = def.options.map((o) => o._zod.pattern);
        return new RegExp(`^(${patterns.map((p) => cleanRegex(p.source)).join("|")})$`);
      }
      return void 0;
    });
    const first = def.options.length === 1 ? def.options[0]._zod.run : null;
    inst._zod.parse = (payload, ctx) => {
      if (first) {
        return first(payload, ctx);
      }
      let async = false;
      const results = [];
      for (const option of def.options) {
        const result = option._zod.run({
          value: payload.value,
          issues: []
        }, ctx);
        if (result instanceof Promise) {
          results.push(result);
          async = true;
        } else {
          if (result.issues.length === 0)
            return result;
          results.push(result);
        }
      }
      if (!async)
        return handleUnionResults(results, payload, inst, ctx);
      return Promise.all(results).then((results2) => {
        return handleUnionResults(results2, payload, inst, ctx);
      });
    };
  });
  const $ZodDiscriminatedUnion = /* @__PURE__ */ $constructor("$ZodDiscriminatedUnion", (inst, def) => {
    def.inclusive = false;
    $ZodUnion.init(inst, def);
    const _super = inst._zod.parse;
    defineLazy(inst._zod, "propValues", () => {
      const propValues = {};
      for (const option of def.options) {
        const pv = option._zod.propValues;
        if (!pv || Object.keys(pv).length === 0)
          throw new Error(`Invalid discriminated union option at index "${def.options.indexOf(option)}"`);
        for (const [k, v] of Object.entries(pv)) {
          if (!propValues[k])
            propValues[k] = /* @__PURE__ */ new Set();
          for (const val of v) {
            propValues[k].add(val);
          }
        }
      }
      return propValues;
    });
    const disc = cached$1(() => {
      const opts = def.options;
      const map = /* @__PURE__ */ new Map();
      for (const o of opts) {
        const values = o._zod.propValues?.[def.discriminator];
        if (!values || values.size === 0)
          throw new Error(`Invalid discriminated union option at index "${def.options.indexOf(o)}"`);
        for (const v of values) {
          if (map.has(v)) {
            throw new Error(`Duplicate discriminator value "${String(v)}"`);
          }
          map.set(v, o);
        }
      }
      return map;
    });
    inst._zod.parse = (payload, ctx) => {
      const input2 = payload.value;
      if (!isObject(input2)) {
        payload.issues.push({
          code: "invalid_type",
          expected: "object",
          input: input2,
          inst
        });
        return payload;
      }
      const opt = disc.value.get(input2?.[def.discriminator]);
      if (opt) {
        return opt._zod.run(payload, ctx);
      }
      if (def.unionFallback || ctx.direction === "backward") {
        return _super(payload, ctx);
      }
      payload.issues.push({
        code: "invalid_union",
        errors: [],
        note: "No matching discriminator",
        discriminator: def.discriminator,
        options: Array.from(disc.value.keys()),
        input: input2,
        path: [def.discriminator],
        inst
      });
      return payload;
    };
  });
  const $ZodIntersection = /* @__PURE__ */ $constructor("$ZodIntersection", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.parse = (payload, ctx) => {
      const input2 = payload.value;
      const left = def.left._zod.run({ value: input2, issues: [] }, ctx);
      const right = def.right._zod.run({ value: input2, issues: [] }, ctx);
      const async = left instanceof Promise || right instanceof Promise;
      if (async) {
        return Promise.all([left, right]).then(([left2, right2]) => {
          return handleIntersectionResults(payload, left2, right2);
        });
      }
      return handleIntersectionResults(payload, left, right);
    };
  });
  function mergeValues(a, b) {
    if (a === b) {
      return { valid: true, data: a };
    }
    if (a instanceof Date && b instanceof Date && +a === +b) {
      return { valid: true, data: a };
    }
    if (isPlainObject(a) && isPlainObject(b)) {
      const bKeys = Object.keys(b);
      const sharedKeys = Object.keys(a).filter((key) => bKeys.indexOf(key) !== -1);
      const newObj = { ...a, ...b };
      for (const key of sharedKeys) {
        const sharedValue = mergeValues(a[key], b[key]);
        if (!sharedValue.valid) {
          return {
            valid: false,
            mergeErrorPath: [key, ...sharedValue.mergeErrorPath]
          };
        }
        newObj[key] = sharedValue.data;
      }
      return { valid: true, data: newObj };
    }
    if (Array.isArray(a) && Array.isArray(b)) {
      if (a.length !== b.length) {
        return { valid: false, mergeErrorPath: [] };
      }
      const newArray = [];
      for (let index = 0; index < a.length; index++) {
        const itemA = a[index];
        const itemB = b[index];
        const sharedValue = mergeValues(itemA, itemB);
        if (!sharedValue.valid) {
          return {
            valid: false,
            mergeErrorPath: [index, ...sharedValue.mergeErrorPath]
          };
        }
        newArray.push(sharedValue.data);
      }
      return { valid: true, data: newArray };
    }
    return { valid: false, mergeErrorPath: [] };
  }
  function handleIntersectionResults(result, left, right) {
    const unrecKeys = /* @__PURE__ */ new Map();
    let unrecIssue;
    for (const iss of left.issues) {
      if (iss.code === "unrecognized_keys") {
        unrecIssue ?? (unrecIssue = iss);
        for (const k of iss.keys) {
          if (!unrecKeys.has(k))
            unrecKeys.set(k, {});
          unrecKeys.get(k).l = true;
        }
      } else {
        result.issues.push(iss);
      }
    }
    for (const iss of right.issues) {
      if (iss.code === "unrecognized_keys") {
        for (const k of iss.keys) {
          if (!unrecKeys.has(k))
            unrecKeys.set(k, {});
          unrecKeys.get(k).r = true;
        }
      } else {
        result.issues.push(iss);
      }
    }
    const bothKeys = [...unrecKeys].filter(([, f]) => f.l && f.r).map(([k]) => k);
    if (bothKeys.length && unrecIssue) {
      result.issues.push({ ...unrecIssue, keys: bothKeys });
    }
    if (aborted(result))
      return result;
    const merged = mergeValues(left.value, right.value);
    if (!merged.valid) {
      throw new Error(`Unmergable intersection. Error path: ${JSON.stringify(merged.mergeErrorPath)}`);
    }
    result.value = merged.data;
    return result;
  }
  const $ZodRecord = /* @__PURE__ */ $constructor("$ZodRecord", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.parse = (payload, ctx) => {
      const input2 = payload.value;
      if (!isPlainObject(input2)) {
        payload.issues.push({
          expected: "record",
          code: "invalid_type",
          input: input2,
          inst
        });
        return payload;
      }
      const proms = [];
      const values = def.keyType._zod.values;
      if (values) {
        payload.value = {};
        const recordKeys = /* @__PURE__ */ new Set();
        for (const key of values) {
          if (typeof key === "string" || typeof key === "number" || typeof key === "symbol") {
            recordKeys.add(typeof key === "number" ? key.toString() : key);
            const keyResult = def.keyType._zod.run({ value: key, issues: [] }, ctx);
            if (keyResult instanceof Promise) {
              throw new Error("Async schemas not supported in object keys currently");
            }
            if (keyResult.issues.length) {
              payload.issues.push({
                code: "invalid_key",
                origin: "record",
                issues: keyResult.issues.map((iss) => finalizeIssue(iss, ctx, config())),
                input: key,
                path: [key],
                inst
              });
              continue;
            }
            const outKey = keyResult.value;
            const result = def.valueType._zod.run({ value: input2[key], issues: [] }, ctx);
            if (result instanceof Promise) {
              proms.push(result.then((result2) => {
                if (result2.issues.length) {
                  payload.issues.push(...prefixIssues(key, result2.issues));
                }
                payload.value[outKey] = result2.value;
              }));
            } else {
              if (result.issues.length) {
                payload.issues.push(...prefixIssues(key, result.issues));
              }
              payload.value[outKey] = result.value;
            }
          }
        }
        let unrecognized;
        for (const key in input2) {
          if (!recordKeys.has(key)) {
            unrecognized = unrecognized ?? [];
            unrecognized.push(key);
          }
        }
        if (unrecognized && unrecognized.length > 0) {
          payload.issues.push({
            code: "unrecognized_keys",
            input: input2,
            inst,
            keys: unrecognized
          });
        }
      } else {
        payload.value = {};
        for (const key of Reflect.ownKeys(input2)) {
          if (key === "__proto__")
            continue;
          if (!Object.prototype.propertyIsEnumerable.call(input2, key))
            continue;
          let keyResult = def.keyType._zod.run({ value: key, issues: [] }, ctx);
          if (keyResult instanceof Promise) {
            throw new Error("Async schemas not supported in object keys currently");
          }
          const checkNumericKey = typeof key === "string" && number$1.test(key) && keyResult.issues.length;
          if (checkNumericKey) {
            const retryResult = def.keyType._zod.run({ value: Number(key), issues: [] }, ctx);
            if (retryResult instanceof Promise) {
              throw new Error("Async schemas not supported in object keys currently");
            }
            if (retryResult.issues.length === 0) {
              keyResult = retryResult;
            }
          }
          if (keyResult.issues.length) {
            if (def.mode === "loose") {
              payload.value[key] = input2[key];
            } else {
              payload.issues.push({
                code: "invalid_key",
                origin: "record",
                issues: keyResult.issues.map((iss) => finalizeIssue(iss, ctx, config())),
                input: key,
                path: [key],
                inst
              });
            }
            continue;
          }
          const result = def.valueType._zod.run({ value: input2[key], issues: [] }, ctx);
          if (result instanceof Promise) {
            proms.push(result.then((result2) => {
              if (result2.issues.length) {
                payload.issues.push(...prefixIssues(key, result2.issues));
              }
              payload.value[keyResult.value] = result2.value;
            }));
          } else {
            if (result.issues.length) {
              payload.issues.push(...prefixIssues(key, result.issues));
            }
            payload.value[keyResult.value] = result.value;
          }
        }
      }
      if (proms.length) {
        return Promise.all(proms).then(() => payload);
      }
      return payload;
    };
  });
  const $ZodEnum = /* @__PURE__ */ $constructor("$ZodEnum", (inst, def) => {
    $ZodType.init(inst, def);
    const values = getEnumValues(def.entries);
    const valuesSet = new Set(values);
    inst._zod.values = valuesSet;
    inst._zod.pattern = new RegExp(`^(${values.filter((k) => propertyKeyTypes.has(typeof k)).map((o) => typeof o === "string" ? escapeRegex(o) : o.toString()).join("|")})$`);
    inst._zod.parse = (payload, _ctx) => {
      const input2 = payload.value;
      if (valuesSet.has(input2)) {
        return payload;
      }
      payload.issues.push({
        code: "invalid_value",
        values,
        input: input2,
        inst
      });
      return payload;
    };
  });
  const $ZodLiteral = /* @__PURE__ */ $constructor("$ZodLiteral", (inst, def) => {
    $ZodType.init(inst, def);
    if (def.values.length === 0) {
      throw new Error("Cannot create literal schema with no valid values");
    }
    const values = new Set(def.values);
    inst._zod.values = values;
    inst._zod.pattern = new RegExp(`^(${def.values.map((o) => typeof o === "string" ? escapeRegex(o) : o ? escapeRegex(o.toString()) : String(o)).join("|")})$`);
    inst._zod.parse = (payload, _ctx) => {
      const input2 = payload.value;
      if (values.has(input2)) {
        return payload;
      }
      payload.issues.push({
        code: "invalid_value",
        values: def.values,
        input: input2,
        inst
      });
      return payload;
    };
  });
  const $ZodTransform = /* @__PURE__ */ $constructor("$ZodTransform", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.optin = "optional";
    inst._zod.parse = (payload, ctx) => {
      if (ctx.direction === "backward") {
        throw new $ZodEncodeError(inst.constructor.name);
      }
      const _out = def.transform(payload.value, payload);
      if (ctx.async) {
        const output = _out instanceof Promise ? _out : Promise.resolve(_out);
        return output.then((output2) => {
          payload.value = output2;
          payload.fallback = true;
          return payload;
        });
      }
      if (_out instanceof Promise) {
        throw new $ZodAsyncError();
      }
      payload.value = _out;
      payload.fallback = true;
      return payload;
    };
  });
  function handleOptionalResult(result, input2) {
    if (input2 === void 0 && (result.issues.length || result.fallback)) {
      return { issues: [], value: void 0 };
    }
    return result;
  }
  const $ZodOptional = /* @__PURE__ */ $constructor("$ZodOptional", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.optin = "optional";
    inst._zod.optout = "optional";
    defineLazy(inst._zod, "values", () => {
      return def.innerType._zod.values ? /* @__PURE__ */ new Set([...def.innerType._zod.values, void 0]) : void 0;
    });
    defineLazy(inst._zod, "pattern", () => {
      const pattern = def.innerType._zod.pattern;
      return pattern ? new RegExp(`^(${cleanRegex(pattern.source)})?$`) : void 0;
    });
    inst._zod.parse = (payload, ctx) => {
      if (def.innerType._zod.optin === "optional") {
        const input2 = payload.value;
        const result = def.innerType._zod.run(payload, ctx);
        if (result instanceof Promise)
          return result.then((r) => handleOptionalResult(r, input2));
        return handleOptionalResult(result, input2);
      }
      if (payload.value === void 0) {
        return payload;
      }
      return def.innerType._zod.run(payload, ctx);
    };
  });
  const $ZodExactOptional = /* @__PURE__ */ $constructor("$ZodExactOptional", (inst, def) => {
    $ZodOptional.init(inst, def);
    defineLazy(inst._zod, "values", () => def.innerType._zod.values);
    defineLazy(inst._zod, "pattern", () => def.innerType._zod.pattern);
    inst._zod.parse = (payload, ctx) => {
      return def.innerType._zod.run(payload, ctx);
    };
  });
  const $ZodNullable = /* @__PURE__ */ $constructor("$ZodNullable", (inst, def) => {
    $ZodType.init(inst, def);
    defineLazy(inst._zod, "optin", () => def.innerType._zod.optin);
    defineLazy(inst._zod, "optout", () => def.innerType._zod.optout);
    defineLazy(inst._zod, "pattern", () => {
      const pattern = def.innerType._zod.pattern;
      return pattern ? new RegExp(`^(${cleanRegex(pattern.source)}|null)$`) : void 0;
    });
    defineLazy(inst._zod, "values", () => {
      return def.innerType._zod.values ? /* @__PURE__ */ new Set([...def.innerType._zod.values, null]) : void 0;
    });
    inst._zod.parse = (payload, ctx) => {
      if (payload.value === null)
        return payload;
      return def.innerType._zod.run(payload, ctx);
    };
  });
  const $ZodDefault = /* @__PURE__ */ $constructor("$ZodDefault", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.optin = "optional";
    defineLazy(inst._zod, "values", () => def.innerType._zod.values);
    inst._zod.parse = (payload, ctx) => {
      if (ctx.direction === "backward") {
        return def.innerType._zod.run(payload, ctx);
      }
      if (payload.value === void 0) {
        payload.value = def.defaultValue;
        return payload;
      }
      const result = def.innerType._zod.run(payload, ctx);
      if (result instanceof Promise) {
        return result.then((result2) => handleDefaultResult(result2, def));
      }
      return handleDefaultResult(result, def);
    };
  });
  function handleDefaultResult(payload, def) {
    if (payload.value === void 0) {
      payload.value = def.defaultValue;
    }
    return payload;
  }
  const $ZodPrefault = /* @__PURE__ */ $constructor("$ZodPrefault", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.optin = "optional";
    defineLazy(inst._zod, "values", () => def.innerType._zod.values);
    inst._zod.parse = (payload, ctx) => {
      if (ctx.direction === "backward") {
        return def.innerType._zod.run(payload, ctx);
      }
      if (payload.value === void 0) {
        payload.value = def.defaultValue;
      }
      return def.innerType._zod.run(payload, ctx);
    };
  });
  const $ZodNonOptional = /* @__PURE__ */ $constructor("$ZodNonOptional", (inst, def) => {
    $ZodType.init(inst, def);
    defineLazy(inst._zod, "values", () => {
      const v = def.innerType._zod.values;
      return v ? new Set([...v].filter((x) => x !== void 0)) : void 0;
    });
    inst._zod.parse = (payload, ctx) => {
      const result = def.innerType._zod.run(payload, ctx);
      if (result instanceof Promise) {
        return result.then((result2) => handleNonOptionalResult(result2, inst));
      }
      return handleNonOptionalResult(result, inst);
    };
  });
  function handleNonOptionalResult(payload, inst) {
    if (!payload.issues.length && payload.value === void 0) {
      payload.issues.push({
        code: "invalid_type",
        expected: "nonoptional",
        input: payload.value,
        inst
      });
    }
    return payload;
  }
  const $ZodCatch = /* @__PURE__ */ $constructor("$ZodCatch", (inst, def) => {
    $ZodType.init(inst, def);
    inst._zod.optin = "optional";
    defineLazy(inst._zod, "optout", () => def.innerType._zod.optout);
    defineLazy(inst._zod, "values", () => def.innerType._zod.values);
    inst._zod.parse = (payload, ctx) => {
      if (ctx.direction === "backward") {
        return def.innerType._zod.run(payload, ctx);
      }
      const result = def.innerType._zod.run(payload, ctx);
      if (result instanceof Promise) {
        return result.then((result2) => {
          payload.value = result2.value;
          if (result2.issues.length) {
            payload.value = def.catchValue({
              ...payload,
              error: {
                issues: result2.issues.map((iss) => finalizeIssue(iss, ctx, config()))
              },
              input: payload.value
            });
            payload.issues = [];
            payload.fallback = true;
          }
          return payload;
        });
      }
      payload.value = result.value;
      if (result.issues.length) {
        payload.value = def.catchValue({
          ...payload,
          error: {
            issues: result.issues.map((iss) => finalizeIssue(iss, ctx, config()))
          },
          input: payload.value
        });
        payload.issues = [];
        payload.fallback = true;
      }
      return payload;
    };
  });
  const $ZodPipe = /* @__PURE__ */ $constructor("$ZodPipe", (inst, def) => {
    $ZodType.init(inst, def);
    defineLazy(inst._zod, "values", () => def.in._zod.values);
    defineLazy(inst._zod, "optin", () => def.in._zod.optin);
    defineLazy(inst._zod, "optout", () => def.out._zod.optout);
    defineLazy(inst._zod, "propValues", () => def.in._zod.propValues);
    inst._zod.parse = (payload, ctx) => {
      if (ctx.direction === "backward") {
        const right = def.out._zod.run(payload, ctx);
        if (right instanceof Promise) {
          return right.then((right2) => handlePipeResult(right2, def.in, ctx));
        }
        return handlePipeResult(right, def.in, ctx);
      }
      const left = def.in._zod.run(payload, ctx);
      if (left instanceof Promise) {
        return left.then((left2) => handlePipeResult(left2, def.out, ctx));
      }
      return handlePipeResult(left, def.out, ctx);
    };
  });
  function handlePipeResult(left, next2, ctx) {
    if (left.issues.length) {
      left.aborted = true;
      return left;
    }
    return next2._zod.run({ value: left.value, issues: left.issues, fallback: left.fallback }, ctx);
  }
  const $ZodReadonly = /* @__PURE__ */ $constructor("$ZodReadonly", (inst, def) => {
    $ZodType.init(inst, def);
    defineLazy(inst._zod, "propValues", () => def.innerType._zod.propValues);
    defineLazy(inst._zod, "values", () => def.innerType._zod.values);
    defineLazy(inst._zod, "optin", () => def.innerType?._zod?.optin);
    defineLazy(inst._zod, "optout", () => def.innerType?._zod?.optout);
    inst._zod.parse = (payload, ctx) => {
      if (ctx.direction === "backward") {
        return def.innerType._zod.run(payload, ctx);
      }
      const result = def.innerType._zod.run(payload, ctx);
      if (result instanceof Promise) {
        return result.then(handleReadonlyResult);
      }
      return handleReadonlyResult(result);
    };
  });
  function handleReadonlyResult(payload) {
    payload.value = Object.freeze(payload.value);
    return payload;
  }
  const $ZodLazy = /* @__PURE__ */ $constructor("$ZodLazy", (inst, def) => {
    $ZodType.init(inst, def);
    defineLazy(inst._zod, "innerType", () => {
      const d = def;
      if (!d._cachedInner)
        d._cachedInner = def.getter();
      return d._cachedInner;
    });
    defineLazy(inst._zod, "pattern", () => inst._zod.innerType?._zod?.pattern);
    defineLazy(inst._zod, "propValues", () => inst._zod.innerType?._zod?.propValues);
    defineLazy(inst._zod, "optin", () => inst._zod.innerType?._zod?.optin ?? void 0);
    defineLazy(inst._zod, "optout", () => inst._zod.innerType?._zod?.optout ?? void 0);
    inst._zod.parse = (payload, ctx) => {
      const inner = inst._zod.innerType;
      return inner._zod.run(payload, ctx);
    };
  });
  const $ZodCustom = /* @__PURE__ */ $constructor("$ZodCustom", (inst, def) => {
    $ZodCheck.init(inst, def);
    $ZodType.init(inst, def);
    inst._zod.parse = (payload, _) => {
      return payload;
    };
    inst._zod.check = (payload) => {
      const input2 = payload.value;
      const r = def.fn(input2);
      if (r instanceof Promise) {
        return r.then((r2) => handleRefineResult(r2, payload, input2, inst));
      }
      handleRefineResult(r, payload, input2, inst);
      return;
    };
  });
  function handleRefineResult(result, payload, input2, inst) {
    if (!result) {
      const _iss = {
        code: "custom",
        input: input2,
        inst,
        // incorporates params.error into issue reporting
        path: [...inst._zod.def.path ?? []],
        // incorporates params.error into issue reporting
        continue: !inst._zod.def.abort
        // params: inst._zod.def.params,
      };
      if (inst._zod.def.params)
        _iss.params = inst._zod.def.params;
      payload.issues.push(issue(_iss));
    }
  }
  var _a;
  class $ZodRegistry {
    constructor() {
      this._map = /* @__PURE__ */ new WeakMap();
      this._idmap = /* @__PURE__ */ new Map();
    }
    add(schema, ..._meta) {
      const meta = _meta[0];
      this._map.set(schema, meta);
      if (meta && typeof meta === "object" && "id" in meta) {
        this._idmap.set(meta.id, schema);
      }
      return this;
    }
    clear() {
      this._map = /* @__PURE__ */ new WeakMap();
      this._idmap = /* @__PURE__ */ new Map();
      return this;
    }
    remove(schema) {
      const meta = this._map.get(schema);
      if (meta && typeof meta === "object" && "id" in meta) {
        this._idmap.delete(meta.id);
      }
      this._map.delete(schema);
      return this;
    }
    get(schema) {
      const p = schema._zod.parent;
      if (p) {
        const pm = { ...this.get(p) ?? {} };
        delete pm.id;
        const f = { ...pm, ...this._map.get(schema) };
        return Object.keys(f).length ? f : void 0;
      }
      return this._map.get(schema);
    }
    has(schema) {
      return this._map.has(schema);
    }
  }
  function registry() {
    return new $ZodRegistry();
  }
  (_a = globalThis).__zod_globalRegistry ?? (_a.__zod_globalRegistry = registry());
  const globalRegistry = globalThis.__zod_globalRegistry;
  // @__NO_SIDE_EFFECTS__
  function _string(Class, params) {
    return new Class({
      type: "string",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _email(Class, params) {
    return new Class({
      type: "string",
      format: "email",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _guid(Class, params) {
    return new Class({
      type: "string",
      format: "guid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _uuid(Class, params) {
    return new Class({
      type: "string",
      format: "uuid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _uuidv4(Class, params) {
    return new Class({
      type: "string",
      format: "uuid",
      check: "string_format",
      abort: false,
      version: "v4",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _uuidv6(Class, params) {
    return new Class({
      type: "string",
      format: "uuid",
      check: "string_format",
      abort: false,
      version: "v6",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _uuidv7(Class, params) {
    return new Class({
      type: "string",
      format: "uuid",
      check: "string_format",
      abort: false,
      version: "v7",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _url(Class, params) {
    return new Class({
      type: "string",
      format: "url",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _emoji(Class, params) {
    return new Class({
      type: "string",
      format: "emoji",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _nanoid(Class, params) {
    return new Class({
      type: "string",
      format: "nanoid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _cuid(Class, params) {
    return new Class({
      type: "string",
      format: "cuid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _cuid2(Class, params) {
    return new Class({
      type: "string",
      format: "cuid2",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _ulid(Class, params) {
    return new Class({
      type: "string",
      format: "ulid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _xid(Class, params) {
    return new Class({
      type: "string",
      format: "xid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _ksuid(Class, params) {
    return new Class({
      type: "string",
      format: "ksuid",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _ipv4(Class, params) {
    return new Class({
      type: "string",
      format: "ipv4",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _ipv6(Class, params) {
    return new Class({
      type: "string",
      format: "ipv6",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _cidrv4(Class, params) {
    return new Class({
      type: "string",
      format: "cidrv4",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _cidrv6(Class, params) {
    return new Class({
      type: "string",
      format: "cidrv6",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _base64(Class, params) {
    return new Class({
      type: "string",
      format: "base64",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _base64url(Class, params) {
    return new Class({
      type: "string",
      format: "base64url",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _e164(Class, params) {
    return new Class({
      type: "string",
      format: "e164",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _jwt(Class, params) {
    return new Class({
      type: "string",
      format: "jwt",
      check: "string_format",
      abort: false,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _isoDateTime(Class, params) {
    return new Class({
      type: "string",
      format: "datetime",
      check: "string_format",
      offset: false,
      local: false,
      precision: null,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _isoDate(Class, params) {
    return new Class({
      type: "string",
      format: "date",
      check: "string_format",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _isoTime(Class, params) {
    return new Class({
      type: "string",
      format: "time",
      check: "string_format",
      precision: null,
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _isoDuration(Class, params) {
    return new Class({
      type: "string",
      format: "duration",
      check: "string_format",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _number(Class, params) {
    return new Class({
      type: "number",
      checks: [],
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _int(Class, params) {
    return new Class({
      type: "number",
      check: "number_format",
      abort: false,
      format: "safeint",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _boolean(Class, params) {
    return new Class({
      type: "boolean",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _undefined$1(Class, params) {
    return new Class({
      type: "undefined",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _null$1(Class, params) {
    return new Class({
      type: "null",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _unknown(Class) {
    return new Class({
      type: "unknown"
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _never(Class, params) {
    return new Class({
      type: "never",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _lt(value, params) {
    return new $ZodCheckLessThan({
      check: "less_than",
      ...normalizeParams(params),
      value,
      inclusive: false
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _lte(value, params) {
    return new $ZodCheckLessThan({
      check: "less_than",
      ...normalizeParams(params),
      value,
      inclusive: true
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _gt(value, params) {
    return new $ZodCheckGreaterThan({
      check: "greater_than",
      ...normalizeParams(params),
      value,
      inclusive: false
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _gte(value, params) {
    return new $ZodCheckGreaterThan({
      check: "greater_than",
      ...normalizeParams(params),
      value,
      inclusive: true
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _multipleOf(value, params) {
    return new $ZodCheckMultipleOf({
      check: "multiple_of",
      ...normalizeParams(params),
      value
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _maxLength(maximum, params) {
    const ch = new $ZodCheckMaxLength({
      check: "max_length",
      ...normalizeParams(params),
      maximum
    });
    return ch;
  }
  // @__NO_SIDE_EFFECTS__
  function _minLength(minimum, params) {
    return new $ZodCheckMinLength({
      check: "min_length",
      ...normalizeParams(params),
      minimum
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _length(length, params) {
    return new $ZodCheckLengthEquals({
      check: "length_equals",
      ...normalizeParams(params),
      length
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _regex(pattern, params) {
    return new $ZodCheckRegex({
      check: "string_format",
      format: "regex",
      ...normalizeParams(params),
      pattern
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _lowercase(params) {
    return new $ZodCheckLowerCase({
      check: "string_format",
      format: "lowercase",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _uppercase(params) {
    return new $ZodCheckUpperCase({
      check: "string_format",
      format: "uppercase",
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _includes(includes, params) {
    return new $ZodCheckIncludes({
      check: "string_format",
      format: "includes",
      ...normalizeParams(params),
      includes
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _startsWith(prefix, params) {
    return new $ZodCheckStartsWith({
      check: "string_format",
      format: "starts_with",
      ...normalizeParams(params),
      prefix
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _endsWith(suffix, params) {
    return new $ZodCheckEndsWith({
      check: "string_format",
      format: "ends_with",
      ...normalizeParams(params),
      suffix
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _overwrite(tx) {
    return new $ZodCheckOverwrite({
      check: "overwrite",
      tx
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _normalize(form) {
    return /* @__PURE__ */ _overwrite((input2) => input2.normalize(form));
  }
  // @__NO_SIDE_EFFECTS__
  function _trim() {
    return /* @__PURE__ */ _overwrite((input2) => input2.trim());
  }
  // @__NO_SIDE_EFFECTS__
  function _toLowerCase() {
    return /* @__PURE__ */ _overwrite((input2) => input2.toLowerCase());
  }
  // @__NO_SIDE_EFFECTS__
  function _toUpperCase() {
    return /* @__PURE__ */ _overwrite((input2) => input2.toUpperCase());
  }
  // @__NO_SIDE_EFFECTS__
  function _slugify() {
    return /* @__PURE__ */ _overwrite((input2) => slugify(input2));
  }
  // @__NO_SIDE_EFFECTS__
  function _array(Class, element, params) {
    return new Class({
      type: "array",
      element,
      // get element() {
      //   return element;
      // },
      ...normalizeParams(params)
    });
  }
  // @__NO_SIDE_EFFECTS__
  function _refine(Class, fn, _params) {
    const schema = new Class({
      type: "custom",
      check: "custom",
      fn,
      ...normalizeParams(_params)
    });
    return schema;
  }
  // @__NO_SIDE_EFFECTS__
  function _superRefine(fn, params) {
    const ch = /* @__PURE__ */ _check((payload) => {
      payload.addIssue = (issue$1) => {
        if (typeof issue$1 === "string") {
          payload.issues.push(issue(issue$1, payload.value, ch._zod.def));
        } else {
          const _issue = issue$1;
          if (_issue.fatal)
            _issue.continue = false;
          _issue.code ?? (_issue.code = "custom");
          _issue.input ?? (_issue.input = payload.value);
          _issue.inst ?? (_issue.inst = ch);
          _issue.continue ?? (_issue.continue = !ch._zod.def.abort);
          payload.issues.push(issue(_issue));
        }
      };
      return fn(payload.value, payload);
    }, params);
    return ch;
  }
  // @__NO_SIDE_EFFECTS__
  function _check(fn, params) {
    const ch = new $ZodCheck({
      check: "custom",
      ...normalizeParams(params)
    });
    ch._zod.check = fn;
    return ch;
  }
  function initializeContext(params) {
    let target = params?.target ?? "draft-2020-12";
    if (target === "draft-4")
      target = "draft-04";
    if (target === "draft-7")
      target = "draft-07";
    return {
      processors: params.processors ?? {},
      metadataRegistry: params?.metadata ?? globalRegistry,
      target,
      unrepresentable: params?.unrepresentable ?? "throw",
      override: params?.override ?? (() => {
      }),
      io: params?.io ?? "output",
      counter: 0,
      seen: /* @__PURE__ */ new Map(),
      cycles: params?.cycles ?? "ref",
      reused: params?.reused ?? "inline",
      external: params?.external ?? void 0
    };
  }
  function process(schema, ctx, _params = { path: [], schemaPath: [] }) {
    var _a2;
    const def = schema._zod.def;
    const seen = ctx.seen.get(schema);
    if (seen) {
      seen.count++;
      const isCycle = _params.schemaPath.includes(schema);
      if (isCycle) {
        seen.cycle = _params.path;
      }
      return seen.schema;
    }
    const result = { schema: {}, count: 1, cycle: void 0, path: _params.path };
    ctx.seen.set(schema, result);
    const overrideSchema = schema._zod.toJSONSchema?.();
    if (overrideSchema) {
      result.schema = overrideSchema;
    } else {
      const params = {
        ..._params,
        schemaPath: [..._params.schemaPath, schema],
        path: _params.path
      };
      if (schema._zod.processJSONSchema) {
        schema._zod.processJSONSchema(ctx, result.schema, params);
      } else {
        const _json = result.schema;
        const processor = ctx.processors[def.type];
        if (!processor) {
          throw new Error(`[toJSONSchema]: Non-representable type encountered: ${def.type}`);
        }
        processor(schema, ctx, _json, params);
      }
      const parent = schema._zod.parent;
      if (parent) {
        if (!result.ref)
          result.ref = parent;
        process(parent, ctx, params);
        ctx.seen.get(parent).isParent = true;
      }
    }
    const meta = ctx.metadataRegistry.get(schema);
    if (meta)
      Object.assign(result.schema, meta);
    if (ctx.io === "input" && isTransforming(schema)) {
      delete result.schema.examples;
      delete result.schema.default;
    }
    if (ctx.io === "input" && "_prefault" in result.schema)
      (_a2 = result.schema).default ?? (_a2.default = result.schema._prefault);
    delete result.schema._prefault;
    const _result = ctx.seen.get(schema);
    return _result.schema;
  }
  function extractDefs(ctx, schema) {
    const root = ctx.seen.get(schema);
    if (!root)
      throw new Error("Unprocessed schema. This is a bug in Zod.");
    const idToSchema = /* @__PURE__ */ new Map();
    for (const entry of ctx.seen.entries()) {
      const id = ctx.metadataRegistry.get(entry[0])?.id;
      if (id) {
        const existing = idToSchema.get(id);
        if (existing && existing !== entry[0]) {
          throw new Error(`Duplicate schema id "${id}" detected during JSON Schema conversion. Two different schemas cannot share the same id when converted together.`);
        }
        idToSchema.set(id, entry[0]);
      }
    }
    const makeURI = (entry) => {
      const defsSegment = ctx.target === "draft-2020-12" ? "$defs" : "definitions";
      if (ctx.external) {
        const externalId = ctx.external.registry.get(entry[0])?.id;
        const uriGenerator = ctx.external.uri ?? ((id2) => id2);
        if (externalId) {
          return { ref: uriGenerator(externalId) };
        }
        const id = entry[1].defId ?? entry[1].schema.id ?? `schema${ctx.counter++}`;
        entry[1].defId = id;
        return { defId: id, ref: `${uriGenerator("__shared")}#/${defsSegment}/${id}` };
      }
      if (entry[1] === root) {
        return { ref: "#" };
      }
      const uriPrefix = `#`;
      const defUriPrefix = `${uriPrefix}/${defsSegment}/`;
      const defId = entry[1].schema.id ?? `__schema${ctx.counter++}`;
      return { defId, ref: defUriPrefix + defId };
    };
    const extractToDef = (entry) => {
      if (entry[1].schema.$ref) {
        return;
      }
      const seen = entry[1];
      const { ref, defId } = makeURI(entry);
      seen.def = { ...seen.schema };
      if (defId)
        seen.defId = defId;
      const schema2 = seen.schema;
      for (const key in schema2) {
        delete schema2[key];
      }
      schema2.$ref = ref;
    };
    if (ctx.cycles === "throw") {
      for (const entry of ctx.seen.entries()) {
        const seen = entry[1];
        if (seen.cycle) {
          throw new Error(`Cycle detected: #/${seen.cycle?.join("/")}/<root>

Set the \`cycles\` parameter to \`"ref"\` to resolve cyclical schemas with defs.`);
        }
      }
    }
    for (const entry of ctx.seen.entries()) {
      const seen = entry[1];
      if (schema === entry[0]) {
        extractToDef(entry);
        continue;
      }
      if (ctx.external) {
        const ext = ctx.external.registry.get(entry[0])?.id;
        if (schema !== entry[0] && ext) {
          extractToDef(entry);
          continue;
        }
      }
      const id = ctx.metadataRegistry.get(entry[0])?.id;
      if (id) {
        extractToDef(entry);
        continue;
      }
      if (seen.cycle) {
        extractToDef(entry);
        continue;
      }
      if (seen.count > 1) {
        if (ctx.reused === "ref") {
          extractToDef(entry);
          continue;
        }
      }
    }
  }
  function finalize(ctx, schema) {
    const root = ctx.seen.get(schema);
    if (!root)
      throw new Error("Unprocessed schema. This is a bug in Zod.");
    const flattenRef = (zodSchema) => {
      const seen = ctx.seen.get(zodSchema);
      if (seen.ref === null)
        return;
      const schema2 = seen.def ?? seen.schema;
      const _cached = { ...schema2 };
      const ref = seen.ref;
      seen.ref = null;
      if (ref) {
        flattenRef(ref);
        const refSeen = ctx.seen.get(ref);
        const refSchema = refSeen.schema;
        if (refSchema.$ref && (ctx.target === "draft-07" || ctx.target === "draft-04" || ctx.target === "openapi-3.0")) {
          schema2.allOf = schema2.allOf ?? [];
          schema2.allOf.push(refSchema);
        } else {
          Object.assign(schema2, refSchema);
        }
        Object.assign(schema2, _cached);
        const isParentRef = zodSchema._zod.parent === ref;
        if (isParentRef) {
          for (const key in schema2) {
            if (key === "$ref" || key === "allOf")
              continue;
            if (!(key in _cached)) {
              delete schema2[key];
            }
          }
        }
        if (refSchema.$ref && refSeen.def) {
          for (const key in schema2) {
            if (key === "$ref" || key === "allOf")
              continue;
            if (key in refSeen.def && JSON.stringify(schema2[key]) === JSON.stringify(refSeen.def[key])) {
              delete schema2[key];
            }
          }
        }
      }
      const parent = zodSchema._zod.parent;
      if (parent && parent !== ref) {
        flattenRef(parent);
        const parentSeen = ctx.seen.get(parent);
        if (parentSeen?.schema.$ref) {
          schema2.$ref = parentSeen.schema.$ref;
          if (parentSeen.def) {
            for (const key in schema2) {
              if (key === "$ref" || key === "allOf")
                continue;
              if (key in parentSeen.def && JSON.stringify(schema2[key]) === JSON.stringify(parentSeen.def[key])) {
                delete schema2[key];
              }
            }
          }
        }
      }
      ctx.override({
        zodSchema,
        jsonSchema: schema2,
        path: seen.path ?? []
      });
    };
    for (const entry of [...ctx.seen.entries()].reverse()) {
      flattenRef(entry[0]);
    }
    const result = {};
    if (ctx.target === "draft-2020-12") {
      result.$schema = "https://json-schema.org/draft/2020-12/schema";
    } else if (ctx.target === "draft-07") {
      result.$schema = "http://json-schema.org/draft-07/schema#";
    } else if (ctx.target === "draft-04") {
      result.$schema = "http://json-schema.org/draft-04/schema#";
    } else if (ctx.target === "openapi-3.0") ;
    else ;
    if (ctx.external?.uri) {
      const id = ctx.external.registry.get(schema)?.id;
      if (!id)
        throw new Error("Schema is missing an `id` property");
      result.$id = ctx.external.uri(id);
    }
    Object.assign(result, root.def ?? root.schema);
    const rootMetaId = ctx.metadataRegistry.get(schema)?.id;
    if (rootMetaId !== void 0 && result.id === rootMetaId)
      delete result.id;
    const defs = ctx.external?.defs ?? {};
    for (const entry of ctx.seen.entries()) {
      const seen = entry[1];
      if (seen.def && seen.defId) {
        if (seen.def.id === seen.defId)
          delete seen.def.id;
        defs[seen.defId] = seen.def;
      }
    }
    if (ctx.external) ;
    else {
      if (Object.keys(defs).length > 0) {
        if (ctx.target === "draft-2020-12") {
          result.$defs = defs;
        } else {
          result.definitions = defs;
        }
      }
    }
    try {
      const finalized = JSON.parse(JSON.stringify(result));
      Object.defineProperty(finalized, "~standard", {
        value: {
          ...schema["~standard"],
          jsonSchema: {
            input: createStandardJSONSchemaMethod(schema, "input", ctx.processors),
            output: createStandardJSONSchemaMethod(schema, "output", ctx.processors)
          }
        },
        enumerable: false,
        writable: false
      });
      return finalized;
    } catch (_err) {
      throw new Error("Error converting schema to JSON.");
    }
  }
  function isTransforming(_schema, _ctx) {
    const ctx = _ctx ?? { seen: /* @__PURE__ */ new Set() };
    if (ctx.seen.has(_schema))
      return false;
    ctx.seen.add(_schema);
    const def = _schema._zod.def;
    if (def.type === "transform")
      return true;
    if (def.type === "array")
      return isTransforming(def.element, ctx);
    if (def.type === "set")
      return isTransforming(def.valueType, ctx);
    if (def.type === "lazy")
      return isTransforming(def.getter(), ctx);
    if (def.type === "promise" || def.type === "optional" || def.type === "nonoptional" || def.type === "nullable" || def.type === "readonly" || def.type === "default" || def.type === "prefault") {
      return isTransforming(def.innerType, ctx);
    }
    if (def.type === "intersection") {
      return isTransforming(def.left, ctx) || isTransforming(def.right, ctx);
    }
    if (def.type === "record" || def.type === "map") {
      return isTransforming(def.keyType, ctx) || isTransforming(def.valueType, ctx);
    }
    if (def.type === "pipe") {
      if (_schema._zod.traits.has("$ZodCodec"))
        return true;
      return isTransforming(def.in, ctx) || isTransforming(def.out, ctx);
    }
    if (def.type === "object") {
      for (const key in def.shape) {
        if (isTransforming(def.shape[key], ctx))
          return true;
      }
      return false;
    }
    if (def.type === "union") {
      for (const option of def.options) {
        if (isTransforming(option, ctx))
          return true;
      }
      return false;
    }
    if (def.type === "tuple") {
      for (const item of def.items) {
        if (isTransforming(item, ctx))
          return true;
      }
      if (def.rest && isTransforming(def.rest, ctx))
        return true;
      return false;
    }
    return false;
  }
  const createToJSONSchemaMethod = (schema, processors = {}) => (params) => {
    const ctx = initializeContext({ ...params, processors });
    process(schema, ctx);
    extractDefs(ctx, schema);
    return finalize(ctx, schema);
  };
  const createStandardJSONSchemaMethod = (schema, io, processors = {}) => (params) => {
    const { libraryOptions, target } = params ?? {};
    const ctx = initializeContext({ ...libraryOptions ?? {}, target, io, processors });
    process(schema, ctx);
    extractDefs(ctx, schema);
    return finalize(ctx, schema);
  };
  const formatMap = {
    guid: "uuid",
    url: "uri",
    datetime: "date-time",
    json_string: "json-string",
    regex: ""
    // do not set
  };
  const stringProcessor = (schema, ctx, _json, _params) => {
    const json = _json;
    json.type = "string";
    const { minimum, maximum, format, patterns, contentEncoding } = schema._zod.bag;
    if (typeof minimum === "number")
      json.minLength = minimum;
    if (typeof maximum === "number")
      json.maxLength = maximum;
    if (format) {
      json.format = formatMap[format] ?? format;
      if (json.format === "")
        delete json.format;
      if (format === "time") {
        delete json.format;
      }
    }
    if (contentEncoding)
      json.contentEncoding = contentEncoding;
    if (patterns && patterns.size > 0) {
      const regexes = [...patterns];
      if (regexes.length === 1)
        json.pattern = regexes[0].source;
      else if (regexes.length > 1) {
        json.allOf = [
          ...regexes.map((regex) => ({
            ...ctx.target === "draft-07" || ctx.target === "draft-04" || ctx.target === "openapi-3.0" ? { type: "string" } : {},
            pattern: regex.source
          }))
        ];
      }
    }
  };
  const numberProcessor = (schema, ctx, _json, _params) => {
    const json = _json;
    const { minimum, maximum, format, multipleOf, exclusiveMaximum, exclusiveMinimum } = schema._zod.bag;
    if (typeof format === "string" && format.includes("int"))
      json.type = "integer";
    else
      json.type = "number";
    const exMin = typeof exclusiveMinimum === "number" && exclusiveMinimum >= (minimum ?? Number.NEGATIVE_INFINITY);
    const exMax = typeof exclusiveMaximum === "number" && exclusiveMaximum <= (maximum ?? Number.POSITIVE_INFINITY);
    const legacy = ctx.target === "draft-04" || ctx.target === "openapi-3.0";
    if (exMin) {
      if (legacy) {
        json.minimum = exclusiveMinimum;
        json.exclusiveMinimum = true;
      } else {
        json.exclusiveMinimum = exclusiveMinimum;
      }
    } else if (typeof minimum === "number") {
      json.minimum = minimum;
    }
    if (exMax) {
      if (legacy) {
        json.maximum = exclusiveMaximum;
        json.exclusiveMaximum = true;
      } else {
        json.exclusiveMaximum = exclusiveMaximum;
      }
    } else if (typeof maximum === "number") {
      json.maximum = maximum;
    }
    if (typeof multipleOf === "number")
      json.multipleOf = multipleOf;
  };
  const booleanProcessor = (_schema, _ctx, json, _params) => {
    json.type = "boolean";
  };
  const nullProcessor = (_schema, ctx, json, _params) => {
    if (ctx.target === "openapi-3.0") {
      json.type = "string";
      json.nullable = true;
      json.enum = [null];
    } else {
      json.type = "null";
    }
  };
  const undefinedProcessor = (_schema, ctx, _json, _params) => {
    if (ctx.unrepresentable === "throw") {
      throw new Error("Undefined cannot be represented in JSON Schema");
    }
  };
  const neverProcessor = (_schema, _ctx, json, _params) => {
    json.not = {};
  };
  const unknownProcessor = (_schema, _ctx, _json, _params) => {
  };
  const enumProcessor = (schema, _ctx, json, _params) => {
    const def = schema._zod.def;
    const values = getEnumValues(def.entries);
    if (values.every((v) => typeof v === "number"))
      json.type = "number";
    if (values.every((v) => typeof v === "string"))
      json.type = "string";
    json.enum = values;
  };
  const literalProcessor = (schema, ctx, json, _params) => {
    const def = schema._zod.def;
    const vals = [];
    for (const val of def.values) {
      if (val === void 0) {
        if (ctx.unrepresentable === "throw") {
          throw new Error("Literal `undefined` cannot be represented in JSON Schema");
        }
      } else if (typeof val === "bigint") {
        if (ctx.unrepresentable === "throw") {
          throw new Error("BigInt literals cannot be represented in JSON Schema");
        } else {
          vals.push(Number(val));
        }
      } else {
        vals.push(val);
      }
    }
    if (vals.length === 0) ;
    else if (vals.length === 1) {
      const val = vals[0];
      json.type = val === null ? "null" : typeof val;
      if (ctx.target === "draft-04" || ctx.target === "openapi-3.0") {
        json.enum = [val];
      } else {
        json.const = val;
      }
    } else {
      if (vals.every((v) => typeof v === "number"))
        json.type = "number";
      if (vals.every((v) => typeof v === "string"))
        json.type = "string";
      if (vals.every((v) => typeof v === "boolean"))
        json.type = "boolean";
      if (vals.every((v) => v === null))
        json.type = "null";
      json.enum = vals;
    }
  };
  const customProcessor = (_schema, ctx, _json, _params) => {
    if (ctx.unrepresentable === "throw") {
      throw new Error("Custom types cannot be represented in JSON Schema");
    }
  };
  const transformProcessor = (_schema, ctx, _json, _params) => {
    if (ctx.unrepresentable === "throw") {
      throw new Error("Transforms cannot be represented in JSON Schema");
    }
  };
  const arrayProcessor = (schema, ctx, _json, params) => {
    const json = _json;
    const def = schema._zod.def;
    const { minimum, maximum } = schema._zod.bag;
    if (typeof minimum === "number")
      json.minItems = minimum;
    if (typeof maximum === "number")
      json.maxItems = maximum;
    json.type = "array";
    json.items = process(def.element, ctx, {
      ...params,
      path: [...params.path, "items"]
    });
  };
  const objectProcessor = (schema, ctx, _json, params) => {
    const json = _json;
    const def = schema._zod.def;
    json.type = "object";
    json.properties = {};
    const shape = def.shape;
    for (const key in shape) {
      json.properties[key] = process(shape[key], ctx, {
        ...params,
        path: [...params.path, "properties", key]
      });
    }
    const allKeys = new Set(Object.keys(shape));
    const requiredKeys = new Set([...allKeys].filter((key) => {
      const v = def.shape[key]._zod;
      if (ctx.io === "input") {
        return v.optin === void 0;
      } else {
        return v.optout === void 0;
      }
    }));
    if (requiredKeys.size > 0) {
      json.required = Array.from(requiredKeys);
    }
    if (def.catchall?._zod.def.type === "never") {
      json.additionalProperties = false;
    } else if (!def.catchall) {
      if (ctx.io === "output")
        json.additionalProperties = false;
    } else if (def.catchall) {
      json.additionalProperties = process(def.catchall, ctx, {
        ...params,
        path: [...params.path, "additionalProperties"]
      });
    }
  };
  const unionProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    const isExclusive = def.inclusive === false;
    const options = def.options.map((x, i) => process(x, ctx, {
      ...params,
      path: [...params.path, isExclusive ? "oneOf" : "anyOf", i]
    }));
    if (isExclusive) {
      json.oneOf = options;
    } else {
      json.anyOf = options;
    }
  };
  const intersectionProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    const a = process(def.left, ctx, {
      ...params,
      path: [...params.path, "allOf", 0]
    });
    const b = process(def.right, ctx, {
      ...params,
      path: [...params.path, "allOf", 1]
    });
    const isSimpleIntersection = (val) => "allOf" in val && Object.keys(val).length === 1;
    const allOf = [
      ...isSimpleIntersection(a) ? a.allOf : [a],
      ...isSimpleIntersection(b) ? b.allOf : [b]
    ];
    json.allOf = allOf;
  };
  const recordProcessor = (schema, ctx, _json, params) => {
    const json = _json;
    const def = schema._zod.def;
    json.type = "object";
    const keyType = def.keyType;
    const keyBag = keyType._zod.bag;
    const patterns = keyBag?.patterns;
    if (def.mode === "loose" && patterns && patterns.size > 0) {
      const valueSchema = process(def.valueType, ctx, {
        ...params,
        path: [...params.path, "patternProperties", "*"]
      });
      json.patternProperties = {};
      for (const pattern of patterns) {
        json.patternProperties[pattern.source] = valueSchema;
      }
    } else {
      if (ctx.target === "draft-07" || ctx.target === "draft-2020-12") {
        json.propertyNames = process(def.keyType, ctx, {
          ...params,
          path: [...params.path, "propertyNames"]
        });
      }
      json.additionalProperties = process(def.valueType, ctx, {
        ...params,
        path: [...params.path, "additionalProperties"]
      });
    }
    const keyValues = keyType._zod.values;
    if (keyValues) {
      const validKeyValues = [...keyValues].filter((v) => typeof v === "string" || typeof v === "number");
      if (validKeyValues.length > 0) {
        json.required = validKeyValues;
      }
    }
  };
  const nullableProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    const inner = process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    if (ctx.target === "openapi-3.0") {
      seen.ref = def.innerType;
      json.nullable = true;
    } else {
      json.anyOf = [inner, { type: "null" }];
    }
  };
  const nonoptionalProcessor = (schema, ctx, _json, params) => {
    const def = schema._zod.def;
    process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = def.innerType;
  };
  const defaultProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = def.innerType;
    json.default = JSON.parse(JSON.stringify(def.defaultValue));
  };
  const prefaultProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = def.innerType;
    if (ctx.io === "input")
      json._prefault = JSON.parse(JSON.stringify(def.defaultValue));
  };
  const catchProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = def.innerType;
    let catchValue;
    try {
      catchValue = def.catchValue(void 0);
    } catch {
      throw new Error("Dynamic catch values are not supported in JSON Schema");
    }
    json.default = catchValue;
  };
  const pipeProcessor = (schema, ctx, _json, params) => {
    const def = schema._zod.def;
    const inIsTransform = def.in._zod.traits.has("$ZodTransform");
    const innerType = ctx.io === "input" ? inIsTransform ? def.out : def.in : def.out;
    process(innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = innerType;
  };
  const readonlyProcessor = (schema, ctx, json, params) => {
    const def = schema._zod.def;
    process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = def.innerType;
    json.readOnly = true;
  };
  const optionalProcessor = (schema, ctx, _json, params) => {
    const def = schema._zod.def;
    process(def.innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = def.innerType;
  };
  const lazyProcessor = (schema, ctx, _json, params) => {
    const innerType = schema._zod.innerType;
    process(innerType, ctx, params);
    const seen = ctx.seen.get(schema);
    seen.ref = innerType;
  };
  const ZodISODateTime = /* @__PURE__ */ $constructor("ZodISODateTime", (inst, def) => {
    $ZodISODateTime.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  function datetime(params) {
    return /* @__PURE__ */ _isoDateTime(ZodISODateTime, params);
  }
  const ZodISODate = /* @__PURE__ */ $constructor("ZodISODate", (inst, def) => {
    $ZodISODate.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  function date(params) {
    return /* @__PURE__ */ _isoDate(ZodISODate, params);
  }
  const ZodISOTime = /* @__PURE__ */ $constructor("ZodISOTime", (inst, def) => {
    $ZodISOTime.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  function time(params) {
    return /* @__PURE__ */ _isoTime(ZodISOTime, params);
  }
  const ZodISODuration = /* @__PURE__ */ $constructor("ZodISODuration", (inst, def) => {
    $ZodISODuration.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  function duration(params) {
    return /* @__PURE__ */ _isoDuration(ZodISODuration, params);
  }
  const initializer = (inst, issues) => {
    $ZodError.init(inst, issues);
    inst.name = "ZodError";
    Object.defineProperties(inst, {
      format: {
        value: (mapper) => formatError(inst, mapper)
        // enumerable: false,
      },
      flatten: {
        value: (mapper) => flattenError(inst, mapper)
        // enumerable: false,
      },
      addIssue: {
        value: (issue2) => {
          inst.issues.push(issue2);
          inst.message = JSON.stringify(inst.issues, jsonStringifyReplacer, 2);
        }
        // enumerable: false,
      },
      addIssues: {
        value: (issues2) => {
          inst.issues.push(...issues2);
          inst.message = JSON.stringify(inst.issues, jsonStringifyReplacer, 2);
        }
        // enumerable: false,
      },
      isEmpty: {
        get() {
          return inst.issues.length === 0;
        }
        // enumerable: false,
      }
    });
  };
  const ZodRealError = /* @__PURE__ */ $constructor("ZodError", initializer, {
    Parent: Error
  });
  const parse = /* @__PURE__ */ _parse(ZodRealError);
  const parseAsync = /* @__PURE__ */ _parseAsync(ZodRealError);
  const safeParse = /* @__PURE__ */ _safeParse(ZodRealError);
  const safeParseAsync = /* @__PURE__ */ _safeParseAsync(ZodRealError);
  const encode = /* @__PURE__ */ _encode(ZodRealError);
  const decode = /* @__PURE__ */ _decode(ZodRealError);
  const encodeAsync = /* @__PURE__ */ _encodeAsync(ZodRealError);
  const decodeAsync = /* @__PURE__ */ _decodeAsync(ZodRealError);
  const safeEncode = /* @__PURE__ */ _safeEncode(ZodRealError);
  const safeDecode = /* @__PURE__ */ _safeDecode(ZodRealError);
  const safeEncodeAsync = /* @__PURE__ */ _safeEncodeAsync(ZodRealError);
  const safeDecodeAsync = /* @__PURE__ */ _safeDecodeAsync(ZodRealError);
  const _installedGroups = /* @__PURE__ */ new WeakMap();
  function _installLazyMethods(inst, group, methods) {
    const proto = Object.getPrototypeOf(inst);
    let installed = _installedGroups.get(proto);
    if (!installed) {
      installed = /* @__PURE__ */ new Set();
      _installedGroups.set(proto, installed);
    }
    if (installed.has(group))
      return;
    installed.add(group);
    for (const key in methods) {
      const fn = methods[key];
      Object.defineProperty(proto, key, {
        configurable: true,
        enumerable: false,
        get() {
          const bound = fn.bind(this);
          Object.defineProperty(this, key, {
            configurable: true,
            writable: true,
            enumerable: true,
            value: bound
          });
          return bound;
        },
        set(v) {
          Object.defineProperty(this, key, {
            configurable: true,
            writable: true,
            enumerable: true,
            value: v
          });
        }
      });
    }
  }
  const ZodType = /* @__PURE__ */ $constructor("ZodType", (inst, def) => {
    $ZodType.init(inst, def);
    Object.assign(inst["~standard"], {
      jsonSchema: {
        input: createStandardJSONSchemaMethod(inst, "input"),
        output: createStandardJSONSchemaMethod(inst, "output")
      }
    });
    inst.toJSONSchema = createToJSONSchemaMethod(inst, {});
    inst.def = def;
    inst.type = def.type;
    Object.defineProperty(inst, "_def", { value: def });
    inst.parse = (data, params) => parse(inst, data, params, { callee: inst.parse });
    inst.safeParse = (data, params) => safeParse(inst, data, params);
    inst.parseAsync = async (data, params) => parseAsync(inst, data, params, { callee: inst.parseAsync });
    inst.safeParseAsync = async (data, params) => safeParseAsync(inst, data, params);
    inst.spa = inst.safeParseAsync;
    inst.encode = (data, params) => encode(inst, data, params);
    inst.decode = (data, params) => decode(inst, data, params);
    inst.encodeAsync = async (data, params) => encodeAsync(inst, data, params);
    inst.decodeAsync = async (data, params) => decodeAsync(inst, data, params);
    inst.safeEncode = (data, params) => safeEncode(inst, data, params);
    inst.safeDecode = (data, params) => safeDecode(inst, data, params);
    inst.safeEncodeAsync = async (data, params) => safeEncodeAsync(inst, data, params);
    inst.safeDecodeAsync = async (data, params) => safeDecodeAsync(inst, data, params);
    _installLazyMethods(inst, "ZodType", {
      check(...chks) {
        const def2 = this.def;
        return this.clone(mergeDefs(def2, {
          checks: [
            ...def2.checks ?? [],
            ...chks.map((ch) => typeof ch === "function" ? { _zod: { check: ch, def: { check: "custom" }, onattach: [] } } : ch)
          ]
        }), { parent: true });
      },
      with(...chks) {
        return this.check(...chks);
      },
      clone(def2, params) {
        return clone(this, def2, params);
      },
      brand() {
        return this;
      },
      register(reg, meta) {
        reg.add(this, meta);
        return this;
      },
      refine(check, params) {
        return this.check(refine(check, params));
      },
      superRefine(refinement, params) {
        return this.check(superRefine(refinement, params));
      },
      overwrite(fn) {
        return this.check(/* @__PURE__ */ _overwrite(fn));
      },
      optional() {
        return optional(this);
      },
      exactOptional() {
        return exactOptional(this);
      },
      nullable() {
        return nullable(this);
      },
      nullish() {
        return optional(nullable(this));
      },
      nonoptional(params) {
        return nonoptional(this, params);
      },
      array() {
        return array(this);
      },
      or(arg) {
        return union([this, arg]);
      },
      and(arg) {
        return intersection(this, arg);
      },
      transform(tx) {
        return pipe(this, transform(tx));
      },
      default(d) {
        return _default(this, d);
      },
      prefault(d) {
        return prefault(this, d);
      },
      catch(params) {
        return _catch(this, params);
      },
      pipe(target) {
        return pipe(this, target);
      },
      readonly() {
        return readonly(this);
      },
      describe(description) {
        const cl = this.clone();
        globalRegistry.add(cl, { description });
        return cl;
      },
      meta(...args) {
        if (args.length === 0)
          return globalRegistry.get(this);
        const cl = this.clone();
        globalRegistry.add(cl, args[0]);
        return cl;
      },
      isOptional() {
        return this.safeParse(void 0).success;
      },
      isNullable() {
        return this.safeParse(null).success;
      },
      apply(fn) {
        return fn(this);
      }
    });
    Object.defineProperty(inst, "description", {
      get() {
        return globalRegistry.get(inst)?.description;
      },
      configurable: true
    });
    return inst;
  });
  const _ZodString = /* @__PURE__ */ $constructor("_ZodString", (inst, def) => {
    $ZodString.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => stringProcessor(inst, ctx, json);
    const bag = inst._zod.bag;
    inst.format = bag.format ?? null;
    inst.minLength = bag.minimum ?? null;
    inst.maxLength = bag.maximum ?? null;
    _installLazyMethods(inst, "_ZodString", {
      regex(...args) {
        return this.check(/* @__PURE__ */ _regex(...args));
      },
      includes(...args) {
        return this.check(/* @__PURE__ */ _includes(...args));
      },
      startsWith(...args) {
        return this.check(/* @__PURE__ */ _startsWith(...args));
      },
      endsWith(...args) {
        return this.check(/* @__PURE__ */ _endsWith(...args));
      },
      min(...args) {
        return this.check(/* @__PURE__ */ _minLength(...args));
      },
      max(...args) {
        return this.check(/* @__PURE__ */ _maxLength(...args));
      },
      length(...args) {
        return this.check(/* @__PURE__ */ _length(...args));
      },
      nonempty(...args) {
        return this.check(/* @__PURE__ */ _minLength(1, ...args));
      },
      lowercase(params) {
        return this.check(/* @__PURE__ */ _lowercase(params));
      },
      uppercase(params) {
        return this.check(/* @__PURE__ */ _uppercase(params));
      },
      trim() {
        return this.check(/* @__PURE__ */ _trim());
      },
      normalize(...args) {
        return this.check(/* @__PURE__ */ _normalize(...args));
      },
      toLowerCase() {
        return this.check(/* @__PURE__ */ _toLowerCase());
      },
      toUpperCase() {
        return this.check(/* @__PURE__ */ _toUpperCase());
      },
      slugify() {
        return this.check(/* @__PURE__ */ _slugify());
      }
    });
  });
  const ZodString = /* @__PURE__ */ $constructor("ZodString", (inst, def) => {
    $ZodString.init(inst, def);
    _ZodString.init(inst, def);
    inst.email = (params) => inst.check(/* @__PURE__ */ _email(ZodEmail, params));
    inst.url = (params) => inst.check(/* @__PURE__ */ _url(ZodURL, params));
    inst.jwt = (params) => inst.check(/* @__PURE__ */ _jwt(ZodJWT, params));
    inst.emoji = (params) => inst.check(/* @__PURE__ */ _emoji(ZodEmoji, params));
    inst.guid = (params) => inst.check(/* @__PURE__ */ _guid(ZodGUID, params));
    inst.uuid = (params) => inst.check(/* @__PURE__ */ _uuid(ZodUUID, params));
    inst.uuidv4 = (params) => inst.check(/* @__PURE__ */ _uuidv4(ZodUUID, params));
    inst.uuidv6 = (params) => inst.check(/* @__PURE__ */ _uuidv6(ZodUUID, params));
    inst.uuidv7 = (params) => inst.check(/* @__PURE__ */ _uuidv7(ZodUUID, params));
    inst.nanoid = (params) => inst.check(/* @__PURE__ */ _nanoid(ZodNanoID, params));
    inst.guid = (params) => inst.check(/* @__PURE__ */ _guid(ZodGUID, params));
    inst.cuid = (params) => inst.check(/* @__PURE__ */ _cuid(ZodCUID, params));
    inst.cuid2 = (params) => inst.check(/* @__PURE__ */ _cuid2(ZodCUID2, params));
    inst.ulid = (params) => inst.check(/* @__PURE__ */ _ulid(ZodULID, params));
    inst.base64 = (params) => inst.check(/* @__PURE__ */ _base64(ZodBase64, params));
    inst.base64url = (params) => inst.check(/* @__PURE__ */ _base64url(ZodBase64URL, params));
    inst.xid = (params) => inst.check(/* @__PURE__ */ _xid(ZodXID, params));
    inst.ksuid = (params) => inst.check(/* @__PURE__ */ _ksuid(ZodKSUID, params));
    inst.ipv4 = (params) => inst.check(/* @__PURE__ */ _ipv4(ZodIPv4, params));
    inst.ipv6 = (params) => inst.check(/* @__PURE__ */ _ipv6(ZodIPv6, params));
    inst.cidrv4 = (params) => inst.check(/* @__PURE__ */ _cidrv4(ZodCIDRv4, params));
    inst.cidrv6 = (params) => inst.check(/* @__PURE__ */ _cidrv6(ZodCIDRv6, params));
    inst.e164 = (params) => inst.check(/* @__PURE__ */ _e164(ZodE164, params));
    inst.datetime = (params) => inst.check(datetime(params));
    inst.date = (params) => inst.check(date(params));
    inst.time = (params) => inst.check(time(params));
    inst.duration = (params) => inst.check(duration(params));
  });
  function string(params) {
    return /* @__PURE__ */ _string(ZodString, params);
  }
  const ZodStringFormat = /* @__PURE__ */ $constructor("ZodStringFormat", (inst, def) => {
    $ZodStringFormat.init(inst, def);
    _ZodString.init(inst, def);
  });
  const ZodEmail = /* @__PURE__ */ $constructor("ZodEmail", (inst, def) => {
    $ZodEmail.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodGUID = /* @__PURE__ */ $constructor("ZodGUID", (inst, def) => {
    $ZodGUID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodUUID = /* @__PURE__ */ $constructor("ZodUUID", (inst, def) => {
    $ZodUUID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodURL = /* @__PURE__ */ $constructor("ZodURL", (inst, def) => {
    $ZodURL.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodEmoji = /* @__PURE__ */ $constructor("ZodEmoji", (inst, def) => {
    $ZodEmoji.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodNanoID = /* @__PURE__ */ $constructor("ZodNanoID", (inst, def) => {
    $ZodNanoID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodCUID = /* @__PURE__ */ $constructor("ZodCUID", (inst, def) => {
    $ZodCUID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodCUID2 = /* @__PURE__ */ $constructor("ZodCUID2", (inst, def) => {
    $ZodCUID2.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodULID = /* @__PURE__ */ $constructor("ZodULID", (inst, def) => {
    $ZodULID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodXID = /* @__PURE__ */ $constructor("ZodXID", (inst, def) => {
    $ZodXID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodKSUID = /* @__PURE__ */ $constructor("ZodKSUID", (inst, def) => {
    $ZodKSUID.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodIPv4 = /* @__PURE__ */ $constructor("ZodIPv4", (inst, def) => {
    $ZodIPv4.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodIPv6 = /* @__PURE__ */ $constructor("ZodIPv6", (inst, def) => {
    $ZodIPv6.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodCIDRv4 = /* @__PURE__ */ $constructor("ZodCIDRv4", (inst, def) => {
    $ZodCIDRv4.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodCIDRv6 = /* @__PURE__ */ $constructor("ZodCIDRv6", (inst, def) => {
    $ZodCIDRv6.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodBase64 = /* @__PURE__ */ $constructor("ZodBase64", (inst, def) => {
    $ZodBase64.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodBase64URL = /* @__PURE__ */ $constructor("ZodBase64URL", (inst, def) => {
    $ZodBase64URL.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodE164 = /* @__PURE__ */ $constructor("ZodE164", (inst, def) => {
    $ZodE164.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodJWT = /* @__PURE__ */ $constructor("ZodJWT", (inst, def) => {
    $ZodJWT.init(inst, def);
    ZodStringFormat.init(inst, def);
  });
  const ZodNumber = /* @__PURE__ */ $constructor("ZodNumber", (inst, def) => {
    $ZodNumber.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => numberProcessor(inst, ctx, json);
    _installLazyMethods(inst, "ZodNumber", {
      gt(value, params) {
        return this.check(/* @__PURE__ */ _gt(value, params));
      },
      gte(value, params) {
        return this.check(/* @__PURE__ */ _gte(value, params));
      },
      min(value, params) {
        return this.check(/* @__PURE__ */ _gte(value, params));
      },
      lt(value, params) {
        return this.check(/* @__PURE__ */ _lt(value, params));
      },
      lte(value, params) {
        return this.check(/* @__PURE__ */ _lte(value, params));
      },
      max(value, params) {
        return this.check(/* @__PURE__ */ _lte(value, params));
      },
      int(params) {
        return this.check(int(params));
      },
      safe(params) {
        return this.check(int(params));
      },
      positive(params) {
        return this.check(/* @__PURE__ */ _gt(0, params));
      },
      nonnegative(params) {
        return this.check(/* @__PURE__ */ _gte(0, params));
      },
      negative(params) {
        return this.check(/* @__PURE__ */ _lt(0, params));
      },
      nonpositive(params) {
        return this.check(/* @__PURE__ */ _lte(0, params));
      },
      multipleOf(value, params) {
        return this.check(/* @__PURE__ */ _multipleOf(value, params));
      },
      step(value, params) {
        return this.check(/* @__PURE__ */ _multipleOf(value, params));
      },
      finite() {
        return this;
      }
    });
    const bag = inst._zod.bag;
    inst.minValue = Math.max(bag.minimum ?? Number.NEGATIVE_INFINITY, bag.exclusiveMinimum ?? Number.NEGATIVE_INFINITY) ?? null;
    inst.maxValue = Math.min(bag.maximum ?? Number.POSITIVE_INFINITY, bag.exclusiveMaximum ?? Number.POSITIVE_INFINITY) ?? null;
    inst.isInt = (bag.format ?? "").includes("int") || Number.isSafeInteger(bag.multipleOf ?? 0.5);
    inst.isFinite = true;
    inst.format = bag.format ?? null;
  });
  function number(params) {
    return /* @__PURE__ */ _number(ZodNumber, params);
  }
  const ZodNumberFormat = /* @__PURE__ */ $constructor("ZodNumberFormat", (inst, def) => {
    $ZodNumberFormat.init(inst, def);
    ZodNumber.init(inst, def);
  });
  function int(params) {
    return /* @__PURE__ */ _int(ZodNumberFormat, params);
  }
  const ZodBoolean = /* @__PURE__ */ $constructor("ZodBoolean", (inst, def) => {
    $ZodBoolean.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => booleanProcessor(inst, ctx, json);
  });
  function boolean(params) {
    return /* @__PURE__ */ _boolean(ZodBoolean, params);
  }
  const ZodUndefined = /* @__PURE__ */ $constructor("ZodUndefined", (inst, def) => {
    $ZodUndefined.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => undefinedProcessor(inst, ctx);
  });
  function _undefined(params) {
    return /* @__PURE__ */ _undefined$1(ZodUndefined, params);
  }
  const ZodNull = /* @__PURE__ */ $constructor("ZodNull", (inst, def) => {
    $ZodNull.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => nullProcessor(inst, ctx, json);
  });
  function _null(params) {
    return /* @__PURE__ */ _null$1(ZodNull, params);
  }
  const ZodUnknown = /* @__PURE__ */ $constructor("ZodUnknown", (inst, def) => {
    $ZodUnknown.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => unknownProcessor();
  });
  function unknown() {
    return /* @__PURE__ */ _unknown(ZodUnknown);
  }
  const ZodNever = /* @__PURE__ */ $constructor("ZodNever", (inst, def) => {
    $ZodNever.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => neverProcessor(inst, ctx, json);
  });
  function never(params) {
    return /* @__PURE__ */ _never(ZodNever, params);
  }
  const ZodArray = /* @__PURE__ */ $constructor("ZodArray", (inst, def) => {
    $ZodArray.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => arrayProcessor(inst, ctx, json, params);
    inst.element = def.element;
    _installLazyMethods(inst, "ZodArray", {
      min(n, params) {
        return this.check(/* @__PURE__ */ _minLength(n, params));
      },
      nonempty(params) {
        return this.check(/* @__PURE__ */ _minLength(1, params));
      },
      max(n, params) {
        return this.check(/* @__PURE__ */ _maxLength(n, params));
      },
      length(n, params) {
        return this.check(/* @__PURE__ */ _length(n, params));
      },
      unwrap() {
        return this.element;
      }
    });
  });
  function array(element, params) {
    return /* @__PURE__ */ _array(ZodArray, element, params);
  }
  const ZodObject = /* @__PURE__ */ $constructor("ZodObject", (inst, def) => {
    $ZodObjectJIT.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => objectProcessor(inst, ctx, json, params);
    defineLazy(inst, "shape", () => {
      return def.shape;
    });
    _installLazyMethods(inst, "ZodObject", {
      keyof() {
        return _enum(Object.keys(this._zod.def.shape));
      },
      catchall(catchall) {
        return this.clone({ ...this._zod.def, catchall });
      },
      passthrough() {
        return this.clone({ ...this._zod.def, catchall: unknown() });
      },
      loose() {
        return this.clone({ ...this._zod.def, catchall: unknown() });
      },
      strict() {
        return this.clone({ ...this._zod.def, catchall: never() });
      },
      strip() {
        return this.clone({ ...this._zod.def, catchall: void 0 });
      },
      extend(incoming) {
        return extend(this, incoming);
      },
      safeExtend(incoming) {
        return safeExtend(this, incoming);
      },
      merge(other) {
        return merge(this, other);
      },
      pick(mask) {
        return pick(this, mask);
      },
      omit(mask) {
        return omit(this, mask);
      },
      partial(...args) {
        return partial(ZodOptional, this, args[0]);
      },
      required(...args) {
        return required(ZodNonOptional, this, args[0]);
      }
    });
  });
  function object(shape, params) {
    const def = {
      type: "object",
      shape: shape ?? {},
      ...normalizeParams(params)
    };
    return new ZodObject(def);
  }
  function strictObject(shape, params) {
    return new ZodObject({
      type: "object",
      shape,
      catchall: never(),
      ...normalizeParams(params)
    });
  }
  const ZodUnion = /* @__PURE__ */ $constructor("ZodUnion", (inst, def) => {
    $ZodUnion.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => unionProcessor(inst, ctx, json, params);
    inst.options = def.options;
  });
  function union(options, params) {
    return new ZodUnion({
      type: "union",
      options,
      ...normalizeParams(params)
    });
  }
  const ZodDiscriminatedUnion = /* @__PURE__ */ $constructor("ZodDiscriminatedUnion", (inst, def) => {
    ZodUnion.init(inst, def);
    $ZodDiscriminatedUnion.init(inst, def);
  });
  function discriminatedUnion(discriminator, options, params) {
    return new ZodDiscriminatedUnion({
      type: "union",
      options,
      discriminator,
      ...normalizeParams(params)
    });
  }
  const ZodIntersection = /* @__PURE__ */ $constructor("ZodIntersection", (inst, def) => {
    $ZodIntersection.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => intersectionProcessor(inst, ctx, json, params);
  });
  function intersection(left, right) {
    return new ZodIntersection({
      type: "intersection",
      left,
      right
    });
  }
  const ZodRecord = /* @__PURE__ */ $constructor("ZodRecord", (inst, def) => {
    $ZodRecord.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => recordProcessor(inst, ctx, json, params);
    inst.keyType = def.keyType;
    inst.valueType = def.valueType;
  });
  function record(keyType, valueType, params) {
    if (!valueType || !valueType._zod) {
      return new ZodRecord({
        type: "record",
        keyType: string(),
        valueType: keyType,
        ...normalizeParams(valueType)
      });
    }
    return new ZodRecord({
      type: "record",
      keyType,
      valueType,
      ...normalizeParams(params)
    });
  }
  const ZodEnum = /* @__PURE__ */ $constructor("ZodEnum", (inst, def) => {
    $ZodEnum.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => enumProcessor(inst, ctx, json);
    inst.enum = def.entries;
    inst.options = Object.values(def.entries);
    const keys = new Set(Object.keys(def.entries));
    inst.extract = (values, params) => {
      const newEntries = {};
      for (const value of values) {
        if (keys.has(value)) {
          newEntries[value] = def.entries[value];
        } else
          throw new Error(`Key ${value} not found in enum`);
      }
      return new ZodEnum({
        ...def,
        checks: [],
        ...normalizeParams(params),
        entries: newEntries
      });
    };
    inst.exclude = (values, params) => {
      const newEntries = { ...def.entries };
      for (const value of values) {
        if (keys.has(value)) {
          delete newEntries[value];
        } else
          throw new Error(`Key ${value} not found in enum`);
      }
      return new ZodEnum({
        ...def,
        checks: [],
        ...normalizeParams(params),
        entries: newEntries
      });
    };
  });
  function _enum(values, params) {
    const entries = Array.isArray(values) ? Object.fromEntries(values.map((v) => [v, v])) : values;
    return new ZodEnum({
      type: "enum",
      entries,
      ...normalizeParams(params)
    });
  }
  const ZodLiteral = /* @__PURE__ */ $constructor("ZodLiteral", (inst, def) => {
    $ZodLiteral.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => literalProcessor(inst, ctx, json);
    inst.values = new Set(def.values);
    Object.defineProperty(inst, "value", {
      get() {
        if (def.values.length > 1) {
          throw new Error("This schema contains multiple valid literal values. Use `.values` instead.");
        }
        return def.values[0];
      }
    });
  });
  function literal(value, params) {
    return new ZodLiteral({
      type: "literal",
      values: Array.isArray(value) ? value : [value],
      ...normalizeParams(params)
    });
  }
  const ZodTransform = /* @__PURE__ */ $constructor("ZodTransform", (inst, def) => {
    $ZodTransform.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => transformProcessor(inst, ctx);
    inst._zod.parse = (payload, _ctx) => {
      if (_ctx.direction === "backward") {
        throw new $ZodEncodeError(inst.constructor.name);
      }
      payload.addIssue = (issue$1) => {
        if (typeof issue$1 === "string") {
          payload.issues.push(issue(issue$1, payload.value, def));
        } else {
          const _issue = issue$1;
          if (_issue.fatal)
            _issue.continue = false;
          _issue.code ?? (_issue.code = "custom");
          _issue.input ?? (_issue.input = payload.value);
          _issue.inst ?? (_issue.inst = inst);
          payload.issues.push(issue(_issue));
        }
      };
      const output = def.transform(payload.value, payload);
      if (output instanceof Promise) {
        return output.then((output2) => {
          payload.value = output2;
          payload.fallback = true;
          return payload;
        });
      }
      payload.value = output;
      payload.fallback = true;
      return payload;
    };
  });
  function transform(fn) {
    return new ZodTransform({
      type: "transform",
      transform: fn
    });
  }
  const ZodOptional = /* @__PURE__ */ $constructor("ZodOptional", (inst, def) => {
    $ZodOptional.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => optionalProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
  });
  function optional(innerType) {
    return new ZodOptional({
      type: "optional",
      innerType
    });
  }
  const ZodExactOptional = /* @__PURE__ */ $constructor("ZodExactOptional", (inst, def) => {
    $ZodExactOptional.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => optionalProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
  });
  function exactOptional(innerType) {
    return new ZodExactOptional({
      type: "optional",
      innerType
    });
  }
  const ZodNullable = /* @__PURE__ */ $constructor("ZodNullable", (inst, def) => {
    $ZodNullable.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => nullableProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
  });
  function nullable(innerType) {
    return new ZodNullable({
      type: "nullable",
      innerType
    });
  }
  const ZodDefault = /* @__PURE__ */ $constructor("ZodDefault", (inst, def) => {
    $ZodDefault.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => defaultProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
    inst.removeDefault = inst.unwrap;
  });
  function _default(innerType, defaultValue) {
    return new ZodDefault({
      type: "default",
      innerType,
      get defaultValue() {
        return typeof defaultValue === "function" ? defaultValue() : shallowClone(defaultValue);
      }
    });
  }
  const ZodPrefault = /* @__PURE__ */ $constructor("ZodPrefault", (inst, def) => {
    $ZodPrefault.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => prefaultProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
  });
  function prefault(innerType, defaultValue) {
    return new ZodPrefault({
      type: "prefault",
      innerType,
      get defaultValue() {
        return typeof defaultValue === "function" ? defaultValue() : shallowClone(defaultValue);
      }
    });
  }
  const ZodNonOptional = /* @__PURE__ */ $constructor("ZodNonOptional", (inst, def) => {
    $ZodNonOptional.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => nonoptionalProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
  });
  function nonoptional(innerType, params) {
    return new ZodNonOptional({
      type: "nonoptional",
      innerType,
      ...normalizeParams(params)
    });
  }
  const ZodCatch = /* @__PURE__ */ $constructor("ZodCatch", (inst, def) => {
    $ZodCatch.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => catchProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
    inst.removeCatch = inst.unwrap;
  });
  function _catch(innerType, catchValue) {
    return new ZodCatch({
      type: "catch",
      innerType,
      catchValue: typeof catchValue === "function" ? catchValue : () => catchValue
    });
  }
  const ZodPipe = /* @__PURE__ */ $constructor("ZodPipe", (inst, def) => {
    $ZodPipe.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => pipeProcessor(inst, ctx, json, params);
    inst.in = def.in;
    inst.out = def.out;
  });
  function pipe(in_, out) {
    return new ZodPipe({
      type: "pipe",
      in: in_,
      out
      // ...util.normalizeParams(params),
    });
  }
  const ZodReadonly = /* @__PURE__ */ $constructor("ZodReadonly", (inst, def) => {
    $ZodReadonly.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => readonlyProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.innerType;
  });
  function readonly(innerType) {
    return new ZodReadonly({
      type: "readonly",
      innerType
    });
  }
  const ZodLazy = /* @__PURE__ */ $constructor("ZodLazy", (inst, def) => {
    $ZodLazy.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => lazyProcessor(inst, ctx, json, params);
    inst.unwrap = () => inst._zod.def.getter();
  });
  function lazy(getter) {
    return new ZodLazy({
      type: "lazy",
      getter
    });
  }
  const ZodCustom = /* @__PURE__ */ $constructor("ZodCustom", (inst, def) => {
    $ZodCustom.init(inst, def);
    ZodType.init(inst, def);
    inst._zod.processJSONSchema = (ctx, json, params) => customProcessor(inst, ctx);
  });
  function refine(fn, _params = {}) {
    return /* @__PURE__ */ _refine(ZodCustom, fn, _params);
  }
  function superRefine(fn, params) {
    return /* @__PURE__ */ _superRefine(fn, params);
  }
  const AFTER_MERGE_TITLE_PREFIX = "Continue: ";
  const AFTER_MERGE_TITLE_ROOM = 64 - AFTER_MERGE_TITLE_PREFIX.length;
  const taskRef = string().trim().min(1).max(64);
  const AFTER_MERGE_DOERS = ["crewmate", "firstmate"];
  object({
    /** Who does it: a crewmate (the default) or the first mate, for a change in the app itself. */
    doer: _enum(AFTER_MERGE_DOERS).optional(),
    /** An existing open task the merge starts, in place of a new one (title, goal, why). */
    task: taskRef.optional(),
    title: string().min(1).max(AFTER_MERGE_TITLE_ROOM).optional(),
    goal: string().min(1).max(1e3).optional(),
    why: string().min(1).max(4e3).optional(),
    /** The project a new step is filed in, by key; the origin's when absent. */
    project: taskRef.optional(),
    /** Tasks whose merge the step waits for, by key: each a `blocks` link into it. */
    blockedBy: array(taskRef).optional()
  });
  const afterMergeShownSchema = object({
    doer: _enum(AFTER_MERGE_DOERS).optional(),
    title: string().min(1).max(500),
    goal: string().max(4e3).optional(),
    key: string().max(64).optional(),
    waitsFor: array(string().max(64)).optional()
  });
  const afterMergeShownListSchema = array(afterMergeShownSchema);
  const cardCornerSchema = object({
    icon: literal("minus"),
    label: string(),
    restWords: string(),
    /** The core's operation lets a view predict the same change without classifying the card again. */
    operation: _enum(["aside", "read", "hide"]).optional()
  });
  const noteDoneSchema = object({
    label: string(),
    restWords: string(),
    /** The click closes the note's task as answered. */
    closesTask: boolean()
  });
  const SPELLINGS = ["fm", "inf"];
  const OWN_SPELLING = "inf";
  function hookAttributes(name) {
    return [OWN_SPELLING, ...SPELLINGS.filter((spelling) => spelling !== OWN_SPELLING)].map(
      (spelling) => `data-${spelling}-${name}`
    );
  }
  const cardEndedSchema = object({
    /** Who ended it: the card's crewmate or the first mate. */
    by: _enum(["crewmate", "firstmate"]),
    /** The author's reason, written for the captain; absent when it gave none. */
    reason: string().optional(),
    at: number(),
    /** The thread's app line, whole, so every view draws the same words. */
    line: string()
  });
  const HOST_OPS = [
    "restore-account",
    "move-flagship",
    "retry-firstmate",
    "try-again",
    "add-plugin",
    "decline-plugin",
    "apply-project-change",
    "decline-project-change",
    "plan-queue",
    "keep-delivery",
    "add-project",
    "decline-project",
    "continue-task",
    "backlog-task",
    "move-task",
    "stop-task",
    "start-task",
    "ask-again",
    "confirm-required-action",
    "defer-required-action",
    "allow-cost",
    "lift-cost-limit",
    "stop-at-cost",
    "secrets-decision"
  ];
  const requiredActionSchema = object({
    id: string().min(1).max(64).regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
    sharedId: string().min(1).max(64).optional(),
    target: string().min(1).max(200),
    title: string().min(1).max(200),
    consequence: string().min(1).max(500),
    instructions: array(string().min(1).max(2e3)).min(1).max(20),
    criterion: string().min(1).max(1e3),
    prerequisites: array(string().min(1).max(64)).max(50),
    completion: discriminatedUnion("kind", [
      object({ kind: literal("manual"), label: string().min(1).max(64) }),
      object({
        kind: literal("device-version"),
        deviceId: string().min(1).max(64),
        minVersion: string().regex(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/)
      })
    ])
  });
  const requiredActionsSchema = array(requiredActionSchema).max(20);
  const requiredActionTextSchema = requiredActionSchema.pick({ title: true, consequence: true, instructions: true, criterion: true }).partial();
  const requiredActionCorrectionSchema = object({
    operationId: string().min(1).max(128),
    actor: _enum(["crewmate", "firstmate"]),
    /** The contributing crewmate's task; absent for the first mate. */
    taskId: string().optional(),
    /** The host's words for who made it, as every view shows them. */
    label: string().min(1).max(160),
    at: number(),
    reason: string().min(1).max(500),
    generation: number().int().positive(),
    previous: requiredActionTextSchema
  });
  object({
    action: string().min(1).max(128),
    source: string().min(1).max(64),
    actionId: string().min(1).max(64),
    expectedGeneration: number().int().positive(),
    patch: requiredActionTextSchema,
    reason: string().min(1).max(500),
    operationId: string().min(1).max(128),
    sameAction: boolean()
  });
  object({
    requirements: array(
      object({
        source: string(),
        offer: string(),
        head: string().optional(),
        action: requiredActionSchema,
        /** Corrections of this requirement's words, oldest first. */
        corrections: array(requiredActionCorrectionSchema).optional()
      })
    ),
    generation: number().int().positive(),
    state: _enum(["blocked", "ready", "deferred", "confirmed", "checked", "cancelled"]),
    cardId: string(),
    presentedGeneration: number().int().nonnegative(),
    activatedAt: number(),
    completedAt: number().optional(),
    cancelledReason: string().optional()
  });
  object({
    cardId: string(),
    state: _enum(["blocked", "ready", "deferred", "confirmed", "checked", "cancelled"]),
    result: string()
  });
  const rigorSchema = _enum(["quick", "standard", "reviewed"]);
  _enum(["pass", "findings", "blocked"]);
  _enum(["low", "medium", "high"]);
  const findingSeveritySchema = _enum(["error", "warning", "info"]);
  const findingActionSchema = _enum(["auto-fix", "ask-user", "no-op"]);
  object({
    id: string().trim().min(1).max(64),
    severity: findingSeveritySchema,
    file: string().trim().min(1).optional(),
    line: number().int().min(1).optional(),
    text: string().trim().min(1).max(4e3),
    action: findingActionSchema
  });
  const settleEffectSchema = object({
    kind: literal("settle"),
    mode: literal("discard"),
    confirm: literal(true).optional(),
    proceedWithOpen: literal(true).optional()
  });
  const mergeEffectSchema = object({
    kind: literal("merge"),
    review: string().min(1).max(64).optional(),
    after: _enum(["close", "continue"]),
    asksFirst: string().min(1).max(400).optional(),
    proceedWithOpen: literal(true).optional()
  });
  const requestWriteEffectSchema = object({
    kind: literal("request_write"),
    ask: string().min(1).max(64),
    /**
     * Only the host's integration approval card declares the duration or
     * refusal; `task` allows it for the rest of the asking task, sent only to
     * a view that lists `integration-task-allow` (INF-2993).
     */
    integration: _enum(["always", "task", "once", "deny"]).optional()
  });
  const deviceMakeSchema = _enum(["link", "command", "user-command"]);
  const signInOnSchema = object({
    deviceId: string().min(1).max(64),
    providerId: string().min(1).max(256)
  });
  const forgeSignInOnSchema = object({
    deviceId: string().min(1).max(64),
    host: string().min(1).max(253)
  });
  const openEffectSchema = object({
    kind: literal("open"),
    target: _enum(["settings", "subscriptions", "projects", "devices", "browser"]),
    savedSignIn: literal(true).optional(),
    signIn: string().min(1).max(253).optional(),
    make: deviceMakeSchema.optional(),
    remove: string().min(1).max(64).optional(),
    // The address, as the line's own value schema read it (`remoteLoginAddressSchema`);
    // `inf:devices:add` reads it again before anything is reached.
    add: string().min(1).max(255).optional(),
    update: string().min(1).max(64).optional(),
    privateSite: string().min(1).max(253).optional(),
    signInOn: signInOnSchema.optional(),
    forgeSignInOn: forgeSignInOnSchema.optional()
  });
  const TASK_LIFECYCLE_OPS = [
    "answer-done",
    "dismiss-question",
    "start-task",
    "start-again",
    "stop-task",
    "continue-task",
    "drop-task",
    "queue-task",
    "unqueue-task",
    "show-card"
  ];
  _enum(TASK_LIFECYCLE_OPS);
  object({
    parts: array(string().min(1).max(64)).max(64),
    waiting: array(string().min(1).max(64)).max(64),
    underway: array(string().min(1).max(64)).max(64)
  });
  strictObject({ panel: string().min(1).max(40) });
  const hostEffectSchema = object({
    kind: literal("host"),
    op: _enum(HOST_OPS),
    arg: string().optional()
  });
  const cardEffectSchema = discriminatedUnion("kind", [
    settleEffectSchema,
    mergeEffectSchema,
    requestWriteEffectSchema,
    openEffectSchema,
    hostEffectSchema
  ]);
  discriminatedUnion("kind", [
    settleEffectSchema,
    mergeEffectSchema,
    requestWriteEffectSchema,
    openEffectSchema
  ]);
  const cardAuthorSchema = _enum(["crewmate", "firstmate", "host"]);
  const PREVIEW_TAGS = /<!--[\s\S]*?(?:-->|$)|<(script|style)(?=[\s>/])[^>]*>(?:[\s\S]*?<\/\1\s*>|[\s\S]*$)|<(\/?)(figure|canvas)(?=[\s>/])[^>]*>/gi;
  function isPreviewBody(body) {
    let figures = 0;
    for (const [, raw, close, tag] of body.matchAll(PREVIEW_TAGS)) {
      const name = (raw ?? tag ?? "").toLowerCase();
      if (name === "style" || name === "canvas" && !close) return true;
      if (name === "script" && figures === 0) return true;
      if (name === "figure") figures = close ? Math.max(0, figures - 1) : figures + 1;
    }
    return false;
  }
  const cardActionSchema = object({
    id: string(),
    label: string(),
    variant: _enum(["primary", "secondary", "ghost", "danger"]).optional(),
    /**
     * The step the emitter would take (interaction P1, WI-10): a decision
     * marks exactly one, and the host renders it primary. This is how a
     * decision carries an answer's proposed next step - no separate kind.
     */
    default: boolean().optional(),
    /**
     * Published compatibility only: contract 4.65 retired non-closing actions,
     * and migration 73 removes them from open cards. Changes come by reply.
     */
    keepsOpen: boolean().optional(),
    /** What the host does on the click; absent = the click returns to the author. */
    effect: cardEffectSchema.optional(),
    /** A destructive choice: rendered in the danger variant. */
    danger: boolean().optional(),
    /**
     * The care the captain's click sets on the card's task before the choice
     * returns to its author like any reply (INF-562, docs/delivery-rigor.md
     * "Raising care from a merge card"). Only the host adds it, to the merge
     * card it words; no agent declares it, and a body's script cannot press it.
     */
    care: rigorSchema.optional(),
    /**
     * The soft hold the captain's click passes at the card's version before
     * its merge runs (INF-1137 friction 6, docs/delivery-rigor.md "Its
     * words"): Merge anyway on failed checks. Only the host adds it, beside
     * the merge it words; no agent declares it, and a body's script cannot
     * press it.
     */
    passes: literal("checks").optional(),
    /** The choice says no to every other one (INF-3108); a decision with none gets `withAppDecline`'s. */
    declines: literal(true).optional()
  });
  const cardDemoSchema = strictObject({
    /** The copy's minted id, `<taskId>-<32 hex>`; its file is `<id>.<kind>`. */
    id: string(),
    /**
     * An MP4, or the single-play GIF a crewmate made when no MP4 could be:
     * `CARD_MEDIA_KINDS` (`./cardPictures`), written out because that module's
     * imports reach this one; `cardPictures.test.ts` holds the two equal.
     */
    kind: _enum(["mp4", "gif"]),
    width: number().int().positive(),
    height: number().int().positive(),
    durationMs: number().int().positive(),
    bytes: number().int().positive(),
    /** The SHA-256 of the bytes the host verified and copied, in hex. */
    sha256: string().regex(/^[0-9a-f]{64}$/)
  });
  const cardPictureSchema = strictObject({
    /** Verified content identity, absent on older pictures. */
    sha256: string().regex(/^[0-9a-f]{64}$/).optional(),
    id: string(),
    alt: string(),
    width: number().int().positive(),
    height: number().int().positive(),
    /** 0-based, in body order; each lone picture is a group of its own. */
    group: number().int().nonnegative(),
    /**
     * The demo recording this picture is the poster of, when it sits in a
     * `figure[data-inf-demo]`: the poster's own id is the recording's poster id.
     */
    demo: cardDemoSchema.optional()
  });
  const LIVE_ATTACHMENT_LABEL_MAX = 32;
  const PROJECT_PAGE_PATH_MAX = 256;
  const liveAttachmentSchema = discriminatedUnion("kind", [
    strictObject({
      kind: literal("browser"),
      label: string().min(1).max(LIVE_ATTACHMENT_LABEL_MAX),
      taskId: string().min(1).max(64),
      session: string().min(1).max(64),
      generation: number().int().positive(),
      handoff: literal(true).optional()
    }),
    strictObject({
      kind: literal("page"),
      label: string().min(1).max(LIVE_ATTACHMENT_LABEL_MAX),
      taskId: string().min(1).max(64),
      path: string().min(1).max(PROJECT_PAGE_PATH_MAX)
    })
  ]);
  const RISK_LEVELS = ["low", "medium", "high"];
  const RISK_WHY_MAX = 100;
  const riskRatingSchema = strictObject({
    level: _enum(RISK_LEVELS),
    why: string().min(1).max(RISK_WHY_MAX)
  });
  const riskDeclarationSchema = strictObject({
    blast: riskRatingSchema,
    behavior: riskRatingSchema,
    undo: riskRatingSchema,
    evidence: riskRatingSchema,
    sensitivity: riskRatingSchema,
    novelty: riskRatingSchema,
    deps: riskRatingSchema
  });
  const riskAssessmentSchema = object({
    declared: riskDeclarationSchema
  });
  function takesTaskFacts(card) {
    if (card.reviewTaskId) return true;
    if (card.actions.some((action) => settleEffectOf(action) || mergeEffectOf(action))) return true;
    return card.risk !== void 0 && card.actions.length === 0;
  }
  function splitSettleFacts(body) {
    const at = Math.max(
      ...SPELLINGS.map((spelling) => body.lastIndexOf(`<div class="${spelling}-facts" data-facts>`))
    );
    if (at < 0) return void 0;
    const close = body.indexOf("</div>", at);
    if (close < 0) return void 0;
    const end = close + "</div>".length;
    return { body: body.slice(0, at) + body.slice(end), facts: body.slice(at, end), at };
  }
  const CARD_WIDTHS = ["regular", "wide", "full"];
  const cardWidthSchema = _enum(CARD_WIDTHS);
  const cardAwaitingSchema = _enum(["answer", "close-out"]);
  const CARD_CHANGE_MARKS_MAX = 512;
  const cardChangesSchema = strictObject({
    /** When the version on the stage was written. */
    at: number(),
    /** Its parts the captain has not seen. */
    added: number().int().nonnegative(),
    /** Parts of the version last seen that it no longer has: counted, never drawn. */
    removed: number().int().nonnegative(),
    /** More than half its parts are new: the line says Rewritten and nothing is marked. */
    rewritten: boolean(),
    /**
     * Where each new part's opening tag starts in `body`, for its change bar.
     * Empty when rewritten, and on a playable preview, whose own code draws it.
     */
    marks: array(number().int().nonnegative()).max(CARD_CHANGE_MARKS_MAX)
  });
  _enum(["chrome", "frame"]);
  const CARD_MAX_ANSWERS = 256;
  const CARD_MAX_ANSWER_VALUES = 256;
  const CARD_ANSWER_NAME_MAX = 200;
  const CARD_ANSWER_TEXT_MAX = 16384;
  const CARD_ANSWERS_MAX_BYTES = 64 * 1024;
  `The card's answers must be JSON no larger than ${CARD_ANSWERS_MAX_BYTES.toLocaleString("en-US")} bytes.`;
  const CARD_WRITTEN_MAX = 500;
  const CARD_REPLY_MAX_CHARS = 4e3;
  const ANYTHING_ELSE_MAX_CHARS = CARD_REPLY_MAX_CHARS;
  const cardAnswerSchema = strictObject({
    name: string().min(1).max(CARD_ANSWER_NAME_MAX),
    values: array(string().max(CARD_ANSWER_TEXT_MAX)).max(CARD_MAX_ANSWER_VALUES),
    labels: array(string().max(CARD_ANSWER_TEXT_MAX)).max(CARD_MAX_ANSWER_VALUES).optional(),
    changed: boolean(),
    json: literal(true).optional(),
    // The Something else field holds itself to CARD_WRITTEN_MAX; the words
    // the card's field sends with a choice are the longest written there is.
    written: string().min(1).max(ANYTHING_ELSE_MAX_CHARS).optional()
  });
  const cardAnswersSchema = array(cardAnswerSchema).max(CARD_MAX_ANSWERS);
  strictObject({ answers: cardAnswersSchema });
  const CARD_QUESTION_LABEL_MAX = 500;
  const CARD_QUESTIONS_MAX_BYTES = 64 * 1024;
  const CARD_QUESTION_KINDS = ["single", "multiple", "text", "opaque"];
  const CARD_QUESTION_GAPS = [
    // No wording is bound to the question itself (an option's label labels the option).
    "no-prompt",
    // The controls sit in different labelled containers, so no one wording is theirs.
    "conflicting-prompt",
    // The wording or an option label ran past CARD_QUESTION_LABEL_MAX.
    "label-truncated",
    // Two options share a value, so a picked value names neither for sure.
    "duplicate-values",
    // One name spans different kinds of control.
    "mixed-controls",
    // A hidden field or a staged snapshot: a setting, not a visible choice.
    "opaque"
  ];
  const cardQuestionOptionSchema = strictObject({
    /** The control's authored value: the option's id. */
    value: string().max(CARD_ANSWER_TEXT_MAX),
    /** The words bound to the option, when any are. */
    label: string().max(CARD_QUESTION_LABEL_MAX).nullable(),
    /** Checked or selected as the author wrote the body. */
    authoredDefault: boolean(),
    disabled: boolean(),
    /** Laid out with no box: in the body, but not on screen. */
    hidden: boolean()
  });
  const cardQuestionSchema = strictObject({
    name: string().min(1).max(CARD_ANSWER_NAME_MAX),
    kind: _enum(CARD_QUESTION_KINDS),
    /** The control type the author used, kept for a reader that wants it. */
    control: _enum([
      "radio",
      "checkbox",
      "select",
      "select-multiple",
      "text",
      "textarea",
      "hidden",
      "staged",
      "mixed"
    ]),
    prompt: string().max(CARD_QUESTION_LABEL_MAX).nullable(),
    promptBasis: _enum(["legend", "labelledby", "aria-label", "label"]).nullable(),
    /** In display order; empty for words and opaque values. */
    options: array(cardQuestionOptionSchema).max(CARD_MAX_ANSWER_VALUES),
    /**
     * Where the proposal came from: the author's own checked/selected/filled
     * state, a single select's first option the browser picks by itself
     * (`implicit-first`, not the author's recommendation), or none.
     */
    defaultBasis: _enum(["authored", "implicit-first", "none"]),
    required: boolean(),
    gaps: array(_enum(CARD_QUESTION_GAPS)).max(CARD_QUESTION_GAPS.length),
    /** A visible question with its wording and every option read whole. */
    complete: boolean(),
    /**
     * The question also offered a Something else row (`data-inf-write-in`,
     * FI3-1002), which `options` leaves out: the captain could write an
     * answer of their own. Absent when it offered none.
     */
    writeIn: literal(true).optional()
  });
  const cardQuestionsSchema = array(cardQuestionSchema).max(CARD_MAX_ANSWERS);
  const cardQuestionsGapSchema = _enum(["no-fresh-reading", "too-large", "invalid"]);
  strictObject({
    id: string().min(8).max(64),
    lifecycleId: string().max(64).optional(),
    offerId: string().max(64).optional(),
    reading: _enum(["fresh", "fallback", "none"]).optional(),
    /** The card showed another offer by the time the reading came back. */
    remounted: literal(true).optional(),
    questions: cardQuestionsSchema.optional(),
    questionsGap: cardQuestionsGapSchema.optional()
  });
  const CARD_ASKED_KINDS = ["asked", "said", "chose", "automation", "from"];
  const cardAskedSchema = strictObject({
    at: number(),
    text: string(),
    kind: _enum(CARD_ASKED_KINDS).optional(),
    choice: string().optional(),
    card: string().optional(),
    key: string().optional(),
    through: number().int().positive().optional()
  });
  strictObject({
    id: string(),
    taskId: string().optional(),
    /** Host-validated independent review of this card’s task (INF-63). */
    reviewTaskId: string().optional(),
    author: cardAuthorSchema,
    /** Higher shows first in the stack. */
    priority: number(),
    title: string(),
    /** Mono metadata line: relative time, crewmate ref. */
    meta: string(),
    /**
     * The model its author ran on, as a label (a crewmate's card). The chrome
     * paints it as a chip beside the meta line, never inside it. Absent on a
     * card with no model to name and on every card written before it.
     */
    model: string().optional(),
    /**
     * Where its task runs, for a crewmate's card from a task on a computer
     * that runs work, as the words after a verb ("on Mac mini", "as Builder";
     * `signInPlace`). The chrome paints it right after the meta line, which
     * gives way to it (docs/helper.md, "A card from there"). Absent on a card
     * from a task that runs here and on every card written before it.
     */
    place: string().optional(),
    /** Semantic HTML rendered only inside a sandboxed iframe. */
    body: string(),
    /** Core-owned presentation and explicit answer receipt (INF-1879). */
    corner: cardCornerSchema.optional(),
    answerDone: object({ taskId: string(), label: string(), restWords: string() }).optional(),
    /** Every live note's one button, Done or Got it (INF-2794). */
    noteDone: noteDoneSchema.optional(),
    requiredActions: requiredActionsSchema.optional(),
    /** The crew's after-merge steps its saved story declared (INF-2796), drawn beside the merge. */
    afterMerge: afterMergeShownListSchema.optional(),
    actions: array(cardActionSchema),
    status: _enum(["streaming", "ready"]),
    createdAt: number(),
    /**
     * The pictures the host verified in the body (card pictures, phase 2;
     * `cards.pictures`): id, alt, size and group, never the bytes. Absent on a
     * card that names none.
     */
    pictures: array(cardPictureSchema).optional(),
    /**
     * The width the host decided at emit (`cards.width`): the body's facts,
     * widened by the author's hint. Absent means default-wide; regular means short plain copy.
     */
    width: cardWidthSchema.optional(),
    /**
     * The one live thing the card points at, which the chrome draws between
     * the body and the buttons (`cards.attachment_json`): a crewmate's
     * labeled door to its task's browser. Absent on every other card.
     */
    attachment: liveAttachmentSchema.optional(),
    /**
     * A merge card's risk assessment (`cards.risk_json`; docs/card-authoring.md
     * "The risk chart"): the levels and lines its crewmate declared, which the chrome draws as a
     * radar at the card's top right. Absent on every other card.
     */
    risk: riskAssessmentSchema.optional(),
    /**
     * False on a card that takes no reply, whoever its author is
     * (docs/card-threads.md "A card with no reply row"): the chrome draws no
     * reply row and the core refuses one (`cardTakesReplies`). The host sets
     * it on the welcome alone (`cards.replies`); absent on every other card,
     * which takes replies as its author allows.
     */
    replies: literal(false).optional(),
    /**
     * Who answers a reply under a card whose author cannot (`cards.answered_by`):
     * the host sets "firstmate" on its stuck alert (`card-stall-<task>`, INF-1670),
     * so the chrome draws a reply row and the first mate answers in the thread,
     * never the task's crewmate. Absent on every other card, which takes replies
     * as its author allows.
     */
    answeredBy: literal("firstmate").optional(),
    /** Declared by the author: replies stay shown; each arrival comes forward. Choices still close. */
    holdsPlace: literal(true).optional(),
    /**
     * The planner declared this card still asks a question and is not the
     * ready plan. Absent means it did not. The host does not infer it.
     */
    asking: literal(true).optional(),
    /**
     * The planner declared this offer design-only. Absent means it did not.
     * The host does not infer it from the card's sentences.
     */
    designOnly: literal(true).optional(),
    /**
     * Its crewmate declared that the captain's choice on it is not its answer
     * but something it goes on from, such as a consent before it uses
     * something sensitive (INF-1226): on a task that only answers, the choice
     * reaches the crewmate and the task stays open. Absent means it did not;
     * the host does not infer it. Kept in `cards.continues`.
     */
    continues: literal(true).optional(),
    /**
     * Its author declared that the card answers the captain's message it is
     * about (INF-1610): the outcome of the work they asked for, or the first
     * mate's own note answering it. Absent means it did not; the host never
     * infers it from the card's words. Kept in `cards.answering`.
     */
    answering: literal(true).optional(),
    /**
     * Off the stage until its author closes out (docs/card-threads.md "When
     * a card reaches the stage"; the captain's Q1, Q4 and Q5 A of
     * 2026-09-27): `answer` while the captain's reply is the newest line on
     * the thread, `close-out` while its author has written on it - a new
     * card, a revision, a thread answer - and has not yet closed out (a
     * crewmate's next report or its idle, the Firstmate's turn end). Absent
     * on a card the stage shows. `CardService` is its one writer.
     */
    awaiting: cardAwaitingSchema.optional(),
    /** Captain-only saved stack visibility, independent of author holds and task gates. */
    minimized: literal(true).optional(),
    /**
     * A reply kept shown at send time (docs/card-threads.md), or a legacy reply:
     * it sorts after new arrivals while awaiting its author, in reply order. The author's
     * close-out clears it, returning the card to its original place. Host stamp,
     * never an author's; `CardService` is its one writer.
     */
    sentBackAt: number().int().nonnegative().optional(),
    /**
     * The card's current occurrence on the stack and the exact version it
     * carries (the human-supervision capture, docs/card-evidence.md): host
     * stamps, never an author's. A reopen starts a new lifecycle and a change
     * to anything the card shows mints a new offer; a status or stage change
     * does not. The shell echoes the offer it mounted with a click, so the
     * record names the version the captain chose from. Absent on a card no
     * capture has stamped.
     */
    lifecycleId: string().max(64).optional(),
    offerId: string().max(64).optional(),
    /**
     * What changed since the captain last saw the card: the host's revised
     * line and change bars. Host-computed on the stage's snapshot, never
     * stored on the row and never an author's.
     */
    changes: cardChangesSchema.optional(),
    /**
     * The captain's message the card is about, as they sent it, which the
     * chrome draws as the "You asked" line (INF-1610): read from the saved
     * message through the card's task, never from the card's words. Host-
     * computed on the stage's snapshot, never stored on the row and never an
     * author's. Absent on a card about no message of theirs.
     */
    asked: cardAskedSchema.optional(),
    /** Snapshot-only: the captain has seen an offer in this lifecycle, from card observations. */
    seen: boolean().optional(),
    /** Snapshot-only: the exact released update, distinct from its historical offer. */
    currentUpdateId: string().max(64).optional(),
    /** An accepted sighting of that exact update, shared by every updated view. */
    currentUpdateSeen: boolean().optional(),
    /**
     * Its author ended it while the captain had seen it (INF-3071): the record
     * has closed it, and the stack keeps drawing it with no actions, one Close
     * and this app line until the captain closes it. Host stamp, never an
     * author's; absent on every live card.
     */
    ended: cardEndedSchema.optional()
  });
  const cardMessageWhoSchema = _enum(["captain", "crewmate", "firstmate", "host"]);
  const REVISION_TARGETS_MAX = 512;
  const revisionTargetSchema = strictObject({
    id: number().int().nonnegative().max(REVISION_TARGETS_MAX + 1),
    label: string().max(160),
    region: _enum(["body", "title", "buttons", "whole", "preview"]),
    start: number().int().nonnegative().optional()
  });
  const cardRevisionSchema = strictObject({
    lifecycleId: string().min(1).max(64),
    offerId: string().min(1).max(64),
    previousOfferId: string().min(1).max(64),
    released: boolean(),
    targets: array(revisionTargetSchema).max(REVISION_TARGETS_MAX + 2),
    removed: number().int().nonnegative()
  });
  const revisionShownSchema = strictObject({
    offerId: string().min(1).max(64),
    targets: array(revisionTargetSchema).max(REVISION_TARGETS_MAX + 2)
  });
  const cardContributorSchema = strictObject({
    actor: _enum(["crewmate", "firstmate"]),
    taskId: string().min(1).max(64).optional(),
    label: string().min(1).max(160)
  });
  const CARD_MUTATION_EFFECTS = [
    "created",
    "revised",
    "reply-only",
    "unchanged",
    "refused"
  ];
  object({
    effect: _enum(CARD_MUTATION_EFFECTS),
    cardId: string(),
    title: string().optional(),
    /** The card's lifecycle and current revision (its offer) after the write. */
    lifecycleId: string().optional(),
    revision: string().optional(),
    /** A required action's generation after the write. */
    generation: number().int().optional(),
    contributor: cardContributorSchema,
    /** The thread line it wrote, and the captain message that line ended. */
    replyId: number().int().optional(),
    answered: number().int().optional(),
    /** A captain message someone had already answered: the line is a comment. */
    alreadyAnswered: object({ messageId: number().int(), by: string(), text: string() }).optional(),
    /** A closed card's dated note. */
    clarification: literal(true).optional(),
    /** What the write kept as it was. */
    unchanged: array(string()).optional(),
    display: _enum(["available", "held"]),
    responseId: string().optional(),
    refusal: string().optional(),
    /** The same operation identity answered its earlier result. */
    repeated: literal(true).optional()
  });
  const cardMessageSchema = strictObject({
    revision: cardRevisionSchema.optional(),
    revisionShown: revisionShownSchema.optional(),
    /** Who wrote a line on a card that is not theirs (`major-15.md`). */
    contributor: cardContributorSchema.optional(),
    /** The captain's message this line answers and ends, by its row id. */
    answersMessage: number().int().positive().optional(),
    /** A dated note added after the card closed; it reopens and changes nothing. */
    clarification: literal(true).optional(),
    /** Row id, ascending with `at`; the renderer's key. */
    id: number(),
    cardId: string(),
    who: cardMessageWhoSchema,
    /** Prose only - no actions, no script, no figure (captain's Q4 B). */
    text: string(),
    at: number(),
    /**
     * On a captain's reply: the settings and answers the card sent with his
     * words, kept beside them rather than in `text`, so the thread shows what
     * he typed and his settings apart (FI3-617). The author still reads both
     * together (`replyWithSettings`).
     */
    answers: cardAnswersSchema.optional()
  });
  strictObject({
    cardId: string(),
    messages: array(cardMessageSchema)
  });
  const PAST_ENDINGS = [
    "chose",
    "dismissed",
    "author-withdrawal",
    "host-withdrawal",
    "task-retired",
    "duplicate",
    "unknown"
  ];
  strictObject({
    id: string(),
    reviewTaskId: string().optional(),
    taskId: string().optional(),
    author: cardAuthorSchema,
    title: string(),
    meta: string(),
    model: string().optional(),
    body: string(),
    actions: array(cardActionSchema.omit({ effect: true })),
    width: cardWidthSchema.optional(),
    requiredActions: requiredActionsSchema.optional(),
    /** The crew's after-merge steps its saved story declared (INF-2796), drawn beside the merge. */
    afterMerge: afterMergeShownListSchema.optional(),
    /** The risk assessment of the version shown, which a past card draws as its live one did. */
    risk: riskAssessmentSchema.optional(),
    ending: strictObject({
      how: _enum(PAST_ENDINGS),
      at: number(),
      /** The action the captain (or a script) chose; set when `how` is `chose`. */
      actionId: string().optional(),
      label: string().optional(),
      by: _enum(["captain", "firstmate", "crewmate", "host", "frame"]).optional()
    }),
    answers: cardAnswersSchema,
    messages: array(cardMessageSchema)
  });
  strictObject({
    mimeType: _enum(["image/png", "image/jpeg", "image/gif", "image/webp"]),
    data: string().min(1).max(75e5),
    /** The file's display name, when the picture came from a file; text, never markup. */
    name: string().max(120).optional()
  });
  function settleEffectOf(action) {
    return action.effect?.kind === "settle" ? action.effect : void 0;
  }
  function mergeEffectOf(action) {
    const effect = action.effect;
    if (effect?.kind === "merge") return effect;
    if (effect?.kind === "settle" && effect.mode === "merge")
      return {
        kind: "merge",
        after: "close",
        ...effect.proceedWithOpen ? { proceedWithOpen: true } : {}
      };
    if (effect?.kind === "request_merge" && typeof effect.review === "string")
      return { kind: "merge", review: effect.review, after: "continue" };
    return void 0;
  }
  object({
    kind: literal("open"),
    target: _enum(["settings", "subscriptions", "projects", "devices", "browser"]),
    /**
     * `browser`: the task's browser view to open, as the card's attachment
     * named it, with the card it came from (docs/task-browser.md, "Asking
     * for help").
     */
    browser: object({
      taskId: string(),
      session: string(),
      generation: number().int().positive(),
      cardId: string()
    }).optional(),
    restoreAccountId: string().optional(),
    /** The host whose sign-in Settings -> Projects starts on arrival. */
    signIn: string().optional(),
    /** Settings -> Devices makes a link, or a command, on arrival. */
    make: deviceMakeSchema.optional(),
    /** Settings -> Devices removes this device on arrival. */
    remove: string().optional(),
    /** Settings -> Devices adds the Mac at this address over Remote Login on arrival. */
    add: string().optional(),
    /** Settings -> Devices updates Firstmate on this computer, added by its address, on arrival. */
    update: string().optional(),
    /** Settings -> General adds this private site for task browsers on arrival; the add checks it again. */
    privateSite: string().optional(),
    /** Settings -> Intelligence starts this sign-in on that computer on arrival. */
    signInOn: signInOnSchema.optional(),
    /** Settings -> Projects starts that computer's own sign-in where projects live on arrival. */
    forgeSignInOn: forgeSignInOnSchema.optional()
  });
  const cardDisplaySchema = strictObject({
    fidelity: _enum(["matched", "mismatched", "legacy-missing", "unavailable"]),
    reportedOfferId: string().max(64).optional(),
    reportedLifecycleId: string().max(64).optional()
  });
  const cardDecisionContextSchema = strictObject({
    at: number(),
    taskId: string(),
    key: string(),
    kind: string(),
    status: string(),
    activity: string().nullable(),
    parentId: string().nullable(),
    gate: strictObject({ kind: string(), ref: string().optional() }).nullable(),
    delivery: strictObject({
      mode: string(),
      changeLabel: string().optional(),
      headSha: string().optional(),
      checks: string().optional(),
      checksAt: number().optional(),
      review: string().optional(),
      reviewSha: string().optional(),
      reviewedAt: number().optional(),
      settlePending: boolean()
    }).nullable(),
    /** The tasks this one waits on, with their status then. */
    blockers: array(strictObject({ id: string(), status: string() })),
    /** The captain's asks this task carries. */
    asks: array(string())
  });
  const CARD_OBSERVATION_NOTE_MAX = 500;
  strictObject({
    reviewTaskId: string().optional(),
    basis: _enum(["emitted", "put", "legacy-initial-snapshot"]),
    /** SHA-256 of the shown content, for a reader matching offers across cards. */
    fingerprint: string(),
    author: cardAuthorSchema,
    title: string(),
    meta: string(),
    model: string().optional(),
    place: string().optional(),
    body: string(),
    requiredActions: requiredActionsSchema.optional(),
    /** The crew's after-merge steps its saved story declared (INF-2796), drawn beside the merge. */
    afterMerge: afterMergeShownListSchema.optional(),
    actions: array(cardActionSchema),
    pictures: array(cardPictureSchema).optional(),
    width: cardWidthSchema.optional(),
    attachment: liveAttachmentSchema.optional(),
    risk: riskAssessmentSchema.optional(),
    asking: literal(true).optional(),
    designOnly: literal(true).optional(),
    continues: literal(true).optional(),
    answering: literal(true).optional(),
    holdsPlace: literal(true).optional()
  });
  strictObject({
    state: _enum(["available", "waiting"]),
    waitingOn: cardAwaitingSchema.optional(),
    cause: _enum(["emit", "revise", "put", "close-out", "reply", "answered", "restore"]),
    closeOut: _enum(["report", "idle", "turn-end", "restart"]).optional(),
    replaces: string().optional(),
    lifecycle: _enum(["started", "reopened", "legacy-initial-snapshot"]).optional(),
    predecessor: string().optional()
  });
  strictObject({
    actionId: string(),
    recognized: boolean(),
    label: string().nullable(),
    closes: boolean(),
    keepsOpen: boolean(),
    effect: cardEffectSchema.nullable(),
    /** A body script's own value, as JSON text (at most 4,096 bytes). */
    frameValue: string().optional(),
    answers: cardAnswersSchema.optional(),
    display: cardDisplaySchema,
    reading: _enum(["fresh", "fallback", "none"]).optional(),
    remounted: literal(true).optional(),
    questions: cardQuestionsSchema.optional(),
    questionsGap: _enum(["absent", "no-fresh-reading", "too-large", "invalid"]).optional(),
    context: cardDecisionContextSchema.optional(),
    contextGap: _enum(["no-task", "task-missing"]).optional(),
    /** Who minted the interaction id: the shell at the gesture, or the host for a click that sent none. */
    interactionSource: _enum(["shell", "host"])
  });
  strictObject({
    messageId: number().int(),
    who: cardMessageWhoSchema,
    /** An interim author line does not release a new answer. */
    interim: literal(true).optional(),
    answers: cardAnswersSchema.optional(),
    display: cardDisplaySchema.optional()
  });
  strictObject({
    reason: _enum([
      "dismissed",
      "author-withdrawal",
      "host-withdrawal",
      "task-retired",
      "duplicate"
    ]),
    note: string().max(CARD_OBSERVATION_NOTE_MAX).optional(),
    duplicateOf: string().optional(),
    display: cardDisplaySchema.optional()
  });
  strictObject({
    interactionId: string(),
    outcome: _enum(["completed", "refused", "failed", "queued"]),
    note: string().max(CARD_OBSERVATION_NOTE_MAX).optional()
  });
  strictObject({
    /** Absent on legacy offer sightings; those never acknowledge a released update. */
    updateId: string().max(64).optional()
  });
  const QUERY_MAX = 200;
  const scopeSchema = string().min(1).max(64);
  const entryIdSchema = string().regex(/^[cf]-[a-z0-9]{6}$/);
  const unavailableSchema = object({ state: literal("unavailable"), reason: string() });
  const knowledgeNamedSchema = object({
    id: string(),
    kind: _enum(["concept", "finding"]),
    title: string(),
    retired: boolean()
  });
  const knowledgeStandingSchema = _enum([
    "checked",
    "unchecked",
    "recheck",
    "differing",
    "superseded",
    "retired"
  ]);
  const knowledgeAttentionSchema = object({
    recheck: boolean(),
    differing: boolean()
  });
  const knowledgeCollectionSchema = object({
    /** `captain` for the private collection, else the project's id. */
    scope: scopeSchema,
    /** The project's name; empty for the private collection, which the browser names itself. */
    name: string(),
    private: boolean(),
    concepts: number().int().nonnegative(),
    findings: number().int().nonnegative(),
    /** Optional for clients of an older minor. */
    directions: number().int().nonnegative().optional()
  });
  discriminatedUnion("state", [
    object({ state: literal("ready"), collections: array(knowledgeCollectionSchema) }),
    unavailableSchema
  ]);
  strictObject({
    scope: scopeSchema,
    /** A concept whose neighborhood alone is drawn. */
    focus: entryIdSchema.optional(),
    /** How far from `focus`: one hop or two. */
    hops: union([literal(1), literal(2)]).optional(),
    /** Words that narrow the graph to the concepts they find. */
    query: string().max(QUERY_MAX).optional()
  });
  const knowledgeGraphConceptSchema = object({
    id: string(),
    title: string(),
    aliases: array(string()),
    /** Active findings about it. */
    findings: number().int().nonnegative(),
    /** Connections it has in the whole collection, drawn or not. */
    degree: number().int().nonnegative()
  });
  const knowledgeConnectionSchema = discriminatedUnion("kind", [
    object({
      kind: literal("claim"),
      /** `claim:<finding id>`. */
      id: string(),
      from: string(),
      to: string(),
      predicate: string(),
      finding: string(),
      standing: knowledgeStandingSchema
    }),
    object({
      kind: literal("context"),
      /** `context:<declaring concept>:<other concept>`. */
      id: string(),
      from: string(),
      to: string(),
      reason: string()
    })
  ]);
  const graphCountsSchema = object({
    concepts: number().int().nonnegative(),
    connections: number().int().nonnegative()
  });
  discriminatedUnion("state", [
    object({
      state: literal("ready"),
      scope: scopeSchema,
      /** The concept the neighborhood is around, while it is still in the collection. */
      focus: string().nullable(),
      concepts: array(knowledgeGraphConceptSchema),
      connections: array(knowledgeConnectionSchema),
      shown: graphCountsSchema,
      total: graphCountsSchema
    }),
    unavailableSchema
  ]);
  strictObject({
    scope: scopeSchema,
    query: string().max(QUERY_MAX).optional(),
    /** From 0. */
    page: number().int().min(0).max(1e4).optional()
  });
  const knowledgeConceptRowSchema = object({
    id: string(),
    title: string(),
    aliases: array(string()),
    explanation: string(),
    findings: number().int().nonnegative()
  });
  discriminatedUnion("state", [
    object({
      state: literal("ready"),
      scope: scopeSchema,
      rows: array(knowledgeConceptRowSchema),
      total: number().int().nonnegative(),
      page: number().int().nonnegative()
    }),
    unavailableSchema
  ]);
  const knowledgeFindingFilterSchema = _enum(["all", "recheck", "differing"]);
  strictObject({
    scope: scopeSchema,
    query: string().max(QUERY_MAX).optional(),
    filter: knowledgeFindingFilterSchema.optional(),
    page: number().int().min(0).max(1e4).optional()
  });
  const knowledgeRelationshipSchema = object({
    from: knowledgeNamedSchema,
    predicate: string(),
    to: knowledgeNamedSchema
  });
  const knowledgeFindingRowSchema = object({
    id: string(),
    statement: string(),
    basis: _enum(["observation", "inference"]),
    /** Where it holds, in its author's words. */
    conditions: string(),
    about: array(knowledgeNamedSchema),
    relationship: knowledgeRelationshipSchema.nullable(),
    standing: knowledgeStandingSchema,
    attention: knowledgeAttentionSchema,
    /** Sources its current revision cites, and checks that support it with evidence. */
    sources: number().int().nonnegative(),
    checks: number().int().nonnegative()
  });
  discriminatedUnion("state", [
    object({
      state: literal("ready"),
      scope: scopeSchema,
      rows: array(knowledgeFindingRowSchema),
      total: number().int().nonnegative(),
      page: number().int().nonnegative()
    }),
    unavailableSchema
  ]);
  const knowledgeDirectionRowSchema = object({
    id: string(),
    kind: literal("direction"),
    text: string(),
    scope: scopeSchema,
    scopeName: string(),
    origin: string(),
    authority: _enum(["instruction", "advice"]),
    revision: number().int().positive(),
    updatedAt: number()
  });
  discriminatedUnion("state", [
    object({
      state: literal("ready"),
      scope: scopeSchema,
      rows: array(knowledgeDirectionRowSchema),
      total: number().int().nonnegative(),
      page: number().int().nonnegative()
    }),
    unavailableSchema
  ]);
  strictObject({
    id: string().min(1).max(64),
    page: number().int().min(0).max(1e4).optional()
  });
  const knowledgeDirectionSchema = knowledgeDirectionRowSchema.extend({
    retired: boolean(),
    createdAt: number(),
    history: array(
      object({
        revision: number().int().positive(),
        op: _enum(["publish", "revise", "retire"]),
        text: string(),
        origin: string(),
        scope: scopeSchema,
        evidence: string(),
        at: number()
      })
    ),
    page: number().int().nonnegative(),
    total: number().int().nonnegative()
  });
  discriminatedUnion("state", [
    object({ state: literal("ready"), direction: knowledgeDirectionSchema }),
    object({ state: literal("missing") }),
    unavailableSchema
  ]);
  const directionChangeIdSchema = string().regex(/^(d:)?[a-z0-9][a-z0-9-]{0,63}$/);
  const directionChangeTextSchema = string().min(1).max(4e3);
  const directionChangeReasonSchema = string().min(1).max(400);
  const directionChangeRevisionSchema = number().int().positive().optional();
  discriminatedUnion("op", [
    strictObject({
      op: literal("add"),
      /** A new id of the caller's choosing; the app makes one when it is absent. */
      id: directionChangeIdSchema.optional(),
      text: directionChangeTextSchema,
      /** `captain` for everywhere, read by the first mate alone; or one project's id, read by its crewmates too. */
      scope: scopeSchema.optional(),
      reason: directionChangeReasonSchema
    }),
    strictObject({
      op: literal("revise"),
      id: directionChangeIdSchema,
      text: directionChangeTextSchema,
      expectedRevision: directionChangeRevisionSchema,
      reason: directionChangeReasonSchema
    }),
    strictObject({
      op: literal("retire"),
      id: directionChangeIdSchema,
      expectedRevision: directionChangeRevisionSchema,
      reason: directionChangeReasonSchema
    })
  ]);
  object({
    op: _enum(["add", "revise", "retire"]),
    direction: knowledgeDirectionRowSchema
  });
  strictObject({
    id: entryIdSchema,
    /** An earlier revision to read instead of the current one. */
    revision: number().int().positive().optional()
  });
  const knowledgeOriginSchema = discriminatedUnion("kind", [
    object({
      kind: literal("file"),
      path: string(),
      startLine: number().int(),
      endLine: number().int(),
      /** The working copy's commit when it was kept; null when it had none. */
      commit: string().nullable(),
      /** The file differed from that commit when it was kept. */
      dirty: boolean()
    }),
    object({ kind: literal("report"), key: string(), event: number().int() }),
    object({ kind: literal("quote"), citation: string() }),
    object({
      kind: literal("article"),
      url: string(),
      title: string(),
      author: string().nullable(),
      published: string().nullable(),
      retrieved: number()
    })
  ]);
  const knowledgeSourceSchema = object({
    id: string(),
    origin: knowledgeOriginSchema,
    /** The text kept when it was cited, at most 32 KB. */
    text: string(),
    capturedAt: number(),
    check: object({
      state: _enum(["unchanged", "changed", "missing", "unknown", "kept"]),
      detail: string()
    })
  });
  const knowledgeCheckSchema = object({
    id: string(),
    /** The finding's revision it checked. */
    revision: number().int().positive(),
    verdict: _enum(["supports", "contradicts", "inconclusive"]),
    method: string(),
    conditions: string(),
    /** Who checked it: Firstmate, or a crewmate by its task. */
    by: string(),
    at: number(),
    sources: array(knowledgeSourceSchema)
  });
  const knowledgeRevisionSchema = object({
    revision: number().int().positive(),
    op: _enum(["publish", "revise", "link", "retire", "restore"]),
    by: string(),
    reason: string(),
    at: number(),
    /** A concept's title or a finding's statement, as that revision said it. */
    title: string()
  });
  const knowledgeRelationSchema = object({
    type: _enum(["contradicts", "supersedes", "duplicates"]),
    reason: string(),
    other: knowledgeNamedSchema,
    /** This entry declares it (it contradicts, supersedes or duplicates the other). */
    outgoing: boolean(),
    by: string(),
    at: number()
  });
  const knowledgeUseSchema = object({
    revision: number().int().positive(),
    by: string(),
    /** The task's key, when the use was a task's. */
    task: string().nullable(),
    purpose: string(),
    at: number()
  });
  const knowledgeEntryConnectionSchema = discriminatedUnion("kind", [
    object({
      kind: literal("claim"),
      id: string(),
      finding: string(),
      from: knowledgeNamedSchema,
      predicate: string(),
      to: knowledgeNamedSchema,
      standing: knowledgeStandingSchema
    }),
    object({
      kind: literal("context"),
      id: string(),
      from: knowledgeNamedSchema,
      to: knowledgeNamedSchema,
      reason: string()
    })
  ]);
  const knowledgeEntrySchema = object({
    id: string(),
    scope: scopeSchema,
    kind: _enum(["concept", "finding"]),
    /** The revision shown, and the entry's current one. */
    revision: number().int().positive(),
    current: number().int().positive(),
    retired: boolean(),
    /** A concept's title or a finding's statement. */
    title: string(),
    aliases: array(string()),
    /** A concept's explanation; empty for a finding. */
    explanation: string(),
    basis: _enum(["observation", "inference"]).nullable(),
    conditions: string(),
    about: array(knowledgeNamedSchema),
    relationship: knowledgeRelationshipSchema.nullable(),
    /** A finding's standing and what it asks; null for a concept. */
    standing: knowledgeStandingSchema.nullable(),
    attention: knowledgeAttentionSchema.nullable(),
    author: string(),
    createdAt: number(),
    /** When the shown revision was made. */
    at: number(),
    /** A concept's connections, claimed and read-together. */
    connections: array(knowledgeEntryConnectionSchema),
    /** A concept's active findings, newest first, at most `KNOWLEDGE_ENTRY_FINDINGS`. */
    findings: array(
      object({ id: string(), statement: string(), standing: knowledgeStandingSchema })
    ),
    findingsTotal: number().int().nonnegative(),
    sources: array(knowledgeSourceSchema),
    checks: array(knowledgeCheckSchema),
    /** Earlier revisions, newest first, at most twenty, and how many older ones are not listed. */
    revisions: array(knowledgeRevisionSchema),
    olderRevisions: number().int().nonnegative(),
    relations: array(knowledgeRelationSchema),
    uses: object({
      count: number().int().nonnegative(),
      recent: array(knowledgeUseSchema)
    })
  });
  discriminatedUnion("state", [
    object({ state: literal("ready"), entry: knowledgeEntrySchema }),
    object({ state: literal("missing") }),
    unavailableSchema
  ]);
  const KNOWLEDGE_ID_IN_TEXT = "(?<![A-Za-z0-9_-])[cf]-[a-z0-9]{6}(?![A-Za-z0-9_-])";
  const KNOWLEDGE_ID_EXACT = /^[cf]-[a-z0-9]{6}$/;
  const KNOWLEDGE_REFS_MAX = 32;
  strictObject({
    ids: array(entryIdSchema).min(1).max(KNOWLEDGE_REFS_MAX)
  });
  const knowledgeRefSchema = object({
    id: string(),
    kind: _enum(["concept", "finding"]),
    scope: scopeSchema,
    /** A concept's title or a finding's statement, as its current revision says it. */
    title: string(),
    revision: number().int().positive(),
    retired: boolean(),
    /** A finding's standing now; null for a concept. */
    standing: knowledgeStandingSchema.nullable()
  });
  discriminatedUnion("state", [
    object({ state: literal("ready"), refs: array(knowledgeRefSchema) }),
    unavailableSchema
  ]);
  strictObject({ task: string().min(1).max(64) });
  const knowledgeTaskUseSchema = object({
    id: string(),
    kind: _enum(["concept", "finding"]),
    scope: scopeSchema,
    /** The revision the work used, and what it said then. */
    revision: number().int().positive(),
    title: string(),
    /** The entry's current revision, and what it says now. */
    current: number().int().positive(),
    currentTitle: string(),
    retired: boolean(),
    /** A finding's standing now; null for a concept. */
    standing: knowledgeStandingSchema.nullable(),
    /** Why the work relied on it, in its own words. */
    purpose: string(),
    at: number()
  });
  discriminatedUnion("state", [
    object({
      state: literal("ready"),
      uses: array(knowledgeTaskUseSchema),
      total: number().int().nonnegative()
    }),
    unavailableSchema
  ]);
  const TASK_KEY_IN_TEXT = "(?<![A-Za-z0-9_-])[A-Z0-9]{2,4}-[0-9]{1,9}(?![A-Za-z0-9_-])";
  const TASK_KEY_EXACT = /^[A-Z0-9]{2,4}-[0-9]{1,9}$/;
  const TASK_KEYS_MAX = 64;
  function taskKeysIn(text) {
    const keys = [];
    for (const match of text.matchAll(new RegExp(TASK_KEY_IN_TEXT, "g"))) {
      if (keys.includes(match[0])) continue;
      keys.push(match[0]);
      if (keys.length === TASK_KEYS_MAX) break;
    }
    return keys;
  }
  const NET_METHODS = ["GET", "HEAD", "POST", "PUT", "PATCH", "DELETE"];
  const NET_BOUNDS = { responseMaxBytes: 1048576 };
  const HEADER_NAME = /^[A-Za-z0-9-]{1,64}$/;
  const RESERVED_REQUEST_HEADERS = [
    "authorization",
    "cookie",
    "host",
    "origin",
    "proxy-authorization",
    "referer",
    "user-agent"
  ];
  const mediatedFetchRequestSchema = strictObject({
    method: _enum(NET_METHODS).default("GET"),
    /** Absolute path on the aliased origin; the host joins it to the origin. */
    path: string().min(1).max(2048).regex(/^\/(?![/\\])/, "an absolute path"),
    query: record(string().min(1).max(256), string().max(2048)).optional(),
    headers: record(string().regex(HEADER_NAME), string().max(4096)).optional().refine(
      (headers) => !headers || Object.keys(headers).every(
        (name) => !RESERVED_REQUEST_HEADERS.includes(name.toLowerCase())
      ),
      "a reserved header"
    ),
    body: string().max(65536).optional()
  });
  const MEDIATED_FETCH_ERROR_CODES = [
    /** No served grant names this plugin and alias. */
    "capability_not_granted",
    /** The alias is granted but the method is not. */
    "method_not_granted",
    "timeout",
    "network",
    "oversized",
    "rate_limited"
  ];
  discriminatedUnion("ok", [
    object({
      ok: literal(true),
      status: number().int().min(100).max(599),
      headers: record(string(), string()),
      /** Text, bounded by NET_BOUNDS.responseMaxBytes at the executor. */
      body: string().max(NET_BOUNDS.responseMaxBytes)
    }),
    object({
      ok: literal(false),
      error: object({ code: _enum(MEDIATED_FETCH_ERROR_CODES), message: string().max(500) })
    })
  ]);
  strictObject({
    pluginId: string().min(2).max(64),
    alias: string().min(1).max(32),
    request: mediatedFetchRequestSchema
  });
  const FRAME_BRIDGE_VERSION = 2;
  const ACTION_VALUE_MAX_BYTES = 4096;
  const FRAME_MAX_PICTURES = 1024;
  const FRAME_PICTURE_SRC_MAX = 16 * 1024 * 1024;
  const FRAME_PICTURE_ALT_MAX = 4096;
  const FRAME_DEMO_SOURCE = "app-frame://media/";
  const FRAME_DEMO_SRC_MAX = 256;
  const FRAME_DEMO_CAPTION_MAX = 4096;
  const DRAWING_SOURCE_PREFIX = "data:image/svg+xml;charset=utf-8,";
  const DRAWING_LOOK = [
    "fill",
    "fill-opacity",
    "fill-rule",
    "stroke",
    "stroke-width",
    "stroke-opacity",
    "stroke-dasharray",
    "stroke-dashoffset",
    "stroke-linecap",
    "stroke-linejoin",
    "stroke-miterlimit",
    "paint-order",
    "opacity",
    "color",
    "stop-color",
    "stop-opacity",
    "visibility",
    "display",
    "font-family",
    "font-size",
    "font-weight",
    "font-style",
    "letter-spacing",
    "text-anchor",
    "dominant-baseline",
    "text-decoration"
  ];
  const DRAWING_WORDS_LOOK = [
    "color",
    "background-color",
    "opacity",
    "visibility",
    "display",
    "box-sizing",
    "font-family",
    "font-size",
    "font-weight",
    "font-style",
    "line-height",
    "letter-spacing",
    "text-align",
    "text-transform",
    "text-decoration",
    "white-space",
    "overflow-wrap",
    "margin-top",
    "margin-right",
    "margin-bottom",
    "margin-left",
    "padding-top",
    "padding-right",
    "padding-bottom",
    "padding-left",
    "border-top-width",
    "border-right-width",
    "border-bottom-width",
    "border-left-width",
    "border-top-style",
    "border-right-style",
    "border-bottom-style",
    "border-left-style",
    "border-top-color",
    "border-right-color",
    "border-bottom-color",
    "border-left-color",
    "border-radius",
    "flex-direction",
    "flex-wrap",
    "align-items",
    "justify-content",
    "gap",
    "list-style-type"
  ];
  const FRAME_DRAFT_MAX = 500;
  const PICTURE_STRIP_SHOWN = 6;
  const correlationId = number().int().positive().max(Number.MAX_SAFE_INTEGER);
  const fmMarker = literal(FRAME_BRIDGE_VERSION);
  const FRAME_STORE_OPS = ["get", "set", "delete", "list"];
  const FRAME_STORE_KEY_MAX = 128;
  const frameRequestSchema = discriminatedUnion("verb", [
    object({
      verb: literal("subscribe"),
      sub: correlationId,
      read: string().min(1).max(64),
      args: record(string(), unknown()).default({})
    }),
    object({ verb: literal("unsubscribe"), sub: correlationId }),
    object({
      verb: literal("action"),
      action: string().min(1).max(200),
      value: unknown().optional()
    }),
    object({
      verb: literal("fetch"),
      alias: string().min(1).max(32),
      request: mediatedFetchRequestSchema
    }),
    object({
      verb: literal("store"),
      op: _enum(FRAME_STORE_OPS),
      key: string().min(1).max(FRAME_STORE_KEY_MAX).optional(),
      value: unknown().optional(),
      prefix: string().max(FRAME_STORE_KEY_MAX).optional()
    })
  ]);
  const framePictureSchema = object({
    src: string().min(1).max(FRAME_PICTURE_SRC_MAX),
    alt: string().max(FRAME_PICTURE_ALT_MAX),
    width: number().int().nonnegative(),
    height: number().int().nonnegative()
  });
  const answerCount = number().int().nonnegative().max(CARD_MAX_ANSWERS);
  const frameAnswerSchema = cardAnswerSchema.extend({
    written: string().min(1).max(CARD_WRITTEN_MAX).optional()
  });
  const frameAnswersSchema = object({
    answered: answerCount,
    of: answerCount,
    changed: answerCount,
    picked: answerCount,
    answers: array(frameAnswerSchema).max(CARD_MAX_ANSWERS)
  });
  const FRAME_TASK_GESTURES = ["rest", "leave", "open"];
  const frameBoxSchema = object({
    top: number().finite(),
    right: number().finite(),
    bottom: number().finite(),
    left: number().finite()
  });
  const frameMessageSchema = discriminatedUnion("type", [
    object({
      fm: fmMarker,
      type: literal("revealed"),
      document: string(),
      seq: correlationId,
      offerId: string().min(1).max(64),
      top: number().finite().nonnegative().max(1e6).optional(),
      height: number().finite().nonnegative().max(1e6).optional()
    }),
    object({
      fm: fmMarker,
      type: literal("ready"),
      document: string().optional(),
      reuseReads: boolean().optional()
    }),
    object({ fm: fmMarker, type: literal("request"), id: correlationId }).loose(),
    object({
      fm: fmMarker,
      type: literal("resize"),
      height: number().finite().nonnegative(),
      document: string().optional(),
      width: number().finite().nonnegative().optional(),
      initialized: boolean().optional(),
      live: boolean().optional(),
      /** A held page's drawing: its scripts and animations wait for `activate`. */
      held: boolean().optional()
    }),
    object({ fm: fmMarker, type: literal("link"), href: string().min(1).max(2048) }),
    /** A press on a `data-inf-draft` control: the start of an ask, for the message box. */
    object({
      fm: fmMarker,
      type: literal("draft"),
      document: string(),
      text: string().min(1).max(FRAME_DRAFT_MAX).regex(/^[^\r\n]*$/)
    }),
    object({
      fm: fmMarker,
      type: literal("image"),
      index: number().int().nonnegative(),
      pictures: array(framePictureSchema).min(1).max(FRAME_MAX_PICTURES)
    }),
    object({
      fm: fmMarker,
      type: literal("demo"),
      /** The recording's served name, as the body's `data-inf-demo` writes it. */
      src: string().min(1).max(FRAME_DEMO_SRC_MAX),
      poster: framePictureSchema,
      caption: string().max(FRAME_DEMO_CAPTION_MAX),
      /** The length the host wrote on the figure; the player reads the real one. */
      durationMs: number().int().nonnegative(),
      /** The Play button (true) or the poster (false), which opens it paused. */
      play: boolean()
    }),
    object({ fm: fmMarker, type: literal("interaction"), document: string() }),
    /** The frame's own window gained or lost the window's focus. */
    object({
      fm: fmMarker,
      type: literal("focused"),
      document: string(),
      focused: boolean()
    }),
    /** A press began in the frame's own window. */
    object({ fm: fmMarker, type: literal("pressed"), document: string() }),
    /** An Escape nothing in a card body used: the body asks to be left for its card. */
    object({ fm: fmMarker, type: literal("escape"), document: string() }),
    object({
      fm: fmMarker,
      type: literal("task"),
      document: string(),
      gesture: _enum(FRAME_TASK_GESTURES),
      key: string().regex(TASK_KEY_EXACT),
      /** Where the key sits in the frame's viewport; only a `rest` carries it. */
      box: frameBoxSchema.optional()
    }),
    /** A click or Enter on a linked knowledge reference: open its entry. */
    object({
      fm: fmMarker,
      type: literal("entry"),
      document: string(),
      id: string().regex(KNOWLEDGE_ID_EXACT)
    }),
    object({ fm: fmMarker, type: literal("pong"), seq: correlationId }),
    frameAnswersSchema.extend({
      fm: fmMarker,
      type: literal("answers"),
      /** Present when the reading answers the host's `collect` of that number. */
      seq: correlationId.optional(),
      /** A collect's question definitions, as the frame read them; validated by the host. */
      questions: unknown().optional(),
      questionsGap: cardQuestionsGapSchema.optional()
    })
  ]);
  const READ_VALUE_DECODER = `function (previous, message) {
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
}`;
  const FRAME_BRIDGE_SCRIPT = `(function () {
  var VERSION = ${FRAME_BRIDGE_VERSION};
  var LABEL_MAX = ${CARD_QUESTION_LABEL_MAX};
  var QUESTIONS_MAX_BYTES = ${CARD_QUESTIONS_MAX_BYTES};
  var WRITTEN_MAX = ${CARD_WRITTEN_MAX};
  var nextId = 1;
  var pending = {};
  var subscriptions = {};
  var receiveReadValue = ${READ_VALUE_DECODER};
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
  var KEY_IN_TEXT = new RegExp(${JSON.stringify(`${TASK_KEY_IN_TEXT}|${KNOWLEDGE_ID_IN_TEXT}`)}, "g");
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
  var OWN = ${JSON.stringify(OWN_SPELLING)};
  var OTHERS = ${JSON.stringify(SPELLINGS.filter((spelling) => spelling !== OWN_SPELLING))};
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
  ${SPELLINGS.map((spelling) => `window.${spelling} = fm;`).join(" ")}
  ${SPELLINGS.map(
    (spelling) => `window.${spelling}Action = function (id) { fm.action(id).catch(function () {}); };`
  ).join(" ")}
  var STRIP_SHOWN = ${PICTURE_STRIP_SHOWN};
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
  var DEMO_SOURCE = ${JSON.stringify(FRAME_DEMO_SOURCE)};
  var DEMO_CAPTION_MAX = ${FRAME_DEMO_CAPTION_MAX};
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
  // A diagram (INF-3107): an inline drawing a press opens in the picture
  // viewer, as a picture does - the outermost drawing in a figure, or one
  // drawn the width of what holds it. A small mark beside words, a drawing
  // inside a control and one in a caption are not diagrams.
  var DRAWING_CONTROL = PICTURE_CONTROL + ", input, select, textarea, figcaption";
  function outermostDrawing(element) {
    var drawing = element && element.closest ? element.closest("svg") : null;
    while (drawing && drawing.parentElement && drawing.parentElement.closest("svg")) {
      drawing = drawing.parentElement.closest("svg");
    }
    return drawing;
  }
  function isDiagram(drawing) {
    if (!drawing || drawing.closest(DRAWING_CONTROL)) return false;
    var figure = drawing.closest("figure");
    if (figure && !figure.hasAttribute("data-inf-demo")) return true;
    var holder = drawing.parentElement;
    if (!holder) return false;
    var space = getComputedStyle(holder);
    if (/^(inline|contents|none)/.test(space.display)) return false;
    var room = holder.clientWidth - (parseFloat(space.paddingLeft) || 0) - (parseFloat(space.paddingRight) || 0);
    return room > 0 && drawing.getBoundingClientRect().width >= room - 1;
  }
  // The diagram as it stands, whole on its own: every element keeps the
  // look the card gave it - the theme's colors, the author's classes, the
  // stylesheet's type - written on the element, with the card's own faces
  // for the families it uses, at its own size, one unit to a pixel. No
  // script and no handler goes with it; the host shows it as a picture,
  // which runs nothing and loads nothing.
  var SVG_SPACE = "http://www.w3.org/2000/svg";
  var DRAWING_LOOK = ${JSON.stringify(DRAWING_LOOK)};
  var DRAWING_WORDS_LOOK = ${JSON.stringify(DRAWING_WORDS_LOOK)};
  function lookOf(element, names, families) {
    var computed = getComputedStyle(element);
    var look = "";
    for (var i = 0; i < names.length; i++) {
      var value = computed.getPropertyValue(names[i]);
      if (value) look += names[i] + ":" + value + ";";
    }
    computed.fontFamily.split(",").forEach(function (family) {
      families[family.trim().replace(/^["']|["']$/g, "").toLowerCase()] = true;
    });
    return look;
  }
  function facesFor(families) {
    var faces = "";
    for (var i = 0; i < document.styleSheets.length; i++) {
      var rules;
      try { rules = document.styleSheets[i].cssRules; } catch (error) { continue; }
      for (var j = 0; j < rules.length; j++) {
        var rule = rules[j];
        if (rule.type !== 5) continue;
        var family = rule.style.getPropertyValue("font-family").trim().replace(/^["']|["']$/g, "").toLowerCase();
        if (families[family]) faces += rule.cssText + "\\n";
      }
    }
    return faces;
  }
  function drawingPicture(drawing) {
    var copy = drawing.cloneNode(true);
    var from = [drawing].concat(Array.prototype.slice.call(drawing.querySelectorAll("*")));
    var to = [copy].concat(Array.prototype.slice.call(copy.querySelectorAll("*")));
    var families = {};
    var scripts = [];
    for (var i = 0; i < from.length; i++) {
      var element = to[i];
      if (element.localName === "script") { scripts.push(element); continue; }
      for (var a = element.attributes.length - 1; a >= 0; a--) {
        if (/^on/i.test(element.attributes[a].name)) element.removeAttribute(element.attributes[a].name);
      }
      element.removeAttribute("tabindex");
      element.removeAttribute("data-inf-picture");
      element.setAttribute("style", lookOf(from[i], from[i].namespaceURI === SVG_SPACE ? DRAWING_LOOK : DRAWING_WORDS_LOOK, families));
    }
    scripts.forEach(function (script) { script.remove(); });
    var box = drawing.viewBox && drawing.viewBox.baseVal;
    var drawn = drawing.getBoundingClientRect();
    var width = box && box.width > 0 ? box.width : drawn.width;
    var height = box && box.height > 0 ? box.height : drawn.height;
    if (!(box && box.width > 0 && box.height > 0)) copy.setAttribute("viewBox", "0 0 " + width + " " + height);
    copy.setAttribute("width", String(width));
    copy.setAttribute("height", String(height));
    var faces = facesFor(families);
    if (faces) {
      var sheet = document.createElementNS(SVG_SPACE, "style");
      sheet.textContent = faces;
      copy.insertBefore(sheet, copy.firstChild);
    }
    var figure = drawing.closest("figure");
    var caption = figure ? figure.querySelector("figcaption") : null;
    var words = caption ? caption.textContent : (figure && figure.getAttribute("aria-label")) || drawing.getAttribute("aria-label") || "";
    return {
      src: ${JSON.stringify(DRAWING_SOURCE_PREFIX)} + encodeURIComponent(new XMLSerializer().serializeToString(copy)),
      alt: (words || "").replace(/\\s+/g, " ").trim().slice(0, ${FRAME_PICTURE_ALT_MAX}),
      width: Math.max(1, Math.round(width)),
      height: Math.max(1, Math.round(height))
    };
  }
  function openDrawing(drawing) {
    post({ type: "image", index: 0, pictures: [drawingPicture(drawing)] });
  }
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
    var drawings = document.querySelectorAll("svg:not([data-inf-picture]):not([tabindex])");
    for (var d = 0; d < drawings.length; d++) {
      var drawing = drawings[d];
      if (outermostDrawing(drawing) !== drawing || !isDiagram(drawing)) continue;
      drawing.setAttribute("data-inf-picture", "");
      drawing.setAttribute("tabindex", "0");
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
    if (caps.pictures && !target.closest(DRAWING_CONTROL)) {
      var drawing = outermostDrawing(target);
      if (drawing && isDiagram(drawing)) {
        openDrawing(drawing);
        return;
      }
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
      if (!event.repeat) {
        if (target.localName === "svg") openDrawing(target);
        else openPicture(target);
      }
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
})();`;
  const FRAME_BRIDGE_SHA256 = "sha256-9tiZIGMkf3qXNDO+dAprln04r0eS5c+SoPTrJfENuxM=";
  const APP_FRAME_SCHEME = "app-frame";
  const CARD_PICTURE_HOST = "images";
  const CARD_MEDIA_HOST = "media";
  const CARD_MEDIA_TYPES = {
    mp4: "video/mp4",
    gif: "image/gif"
  };
  const CARD_PICTURE_TYPES = {
    png: "image/png",
    jpg: "image/jpeg",
    webp: "image/webp"
  };
  const FILE_NAME = /^([A-Za-z0-9_-]{1,64})-([0-9a-f]{32})\.(png|jpg|webp)$/;
  const MEDIA_FILE_NAME = /^([A-Za-z0-9_-]{1,64})-([0-9a-f]{32})\.(mp4|gif)$/;
  function parseCardPictureFileName(name) {
    const match = FILE_NAME.exec(name);
    if (!match) return void 0;
    const [, taskId, , extension] = match;
    if (!taskId || !extension) return void 0;
    return {
      taskId,
      fileName: name,
      contentType: CARD_PICTURE_TYPES[extension]
    };
  }
  function parseCardMediaFileName(name) {
    const match = MEDIA_FILE_NAME.exec(name);
    if (!match) return void 0;
    const [, taskId, , extension] = match;
    if (!taskId || !extension) return void 0;
    const kind = extension;
    return { taskId, fileName: name, kind, contentType: CARD_MEDIA_TYPES[kind] };
  }
  function playableDemoKind(src) {
    const prefix = `${APP_FRAME_SCHEME}://${CARD_MEDIA_HOST}/`;
    return src.startsWith(prefix) ? parseCardMediaFileName(src.slice(prefix.length))?.kind : void 0;
  }
  const DEMO_SOURCE = new RegExp(`data-(?:${SPELLINGS.join("|")})-demo="([^"]*)"`, "g");
  function isPlayableDemoSource(src) {
    return playableDemoKind(src) !== void 0;
  }
  function demoSources(body) {
    const found = /* @__PURE__ */ new Set();
    for (const match of body.matchAll(DEMO_SOURCE)) {
      const src = match[1] ?? "";
      if (isPlayableDemoSource(src)) found.add(src);
    }
    return found;
  }
  const VIEWABLE_DATA_PICTURE = /^data:image\/(png|jpeg|gif|webp)[;,]/;
  function isViewablePictureSource(src) {
    if (VIEWABLE_DATA_PICTURE.test(src) || isDrawingSource(src)) return true;
    const prefix = `${APP_FRAME_SCHEME}://${CARD_PICTURE_HOST}/`;
    return src.startsWith(prefix) && parseCardPictureFileName(src.slice(prefix.length)) !== void 0;
  }
  function viewablePictures(index, pictures, drawings = true) {
    const viewable = (src) => isViewablePictureSource(src) && (drawings || !isDrawingSource(src));
    const clicked = pictures[index];
    if (!clicked || !viewable(clicked.src)) return void 0;
    const kept = pictures.filter((picture) => viewable(picture.src));
    return { index: kept.indexOf(clicked), pictures: kept };
  }
  function isDrawingSource(src) {
    return src.startsWith(DRAWING_SOURCE_PREFIX);
  }
  const FRAME_SANDBOX_TOKENS = ["allow-scripts"];
  const FRAME_SANDBOX = FRAME_SANDBOX_TOKENS.join(" ");
  const FRAME_FONT_SOURCE = `${APP_FRAME_SCHEME}:`;
  const SRCDOC_FONT_SOURCE = `${APP_FRAME_SCHEME}://fonts`;
  const FRAME_IMAGE_SOURCE = `data: ${APP_FRAME_SCHEME}:`;
  function frameCsp(scriptHashes = [], fontSource = FRAME_FONT_SOURCE) {
    const scripts = [FRAME_BRIDGE_SHA256, ...scriptHashes].map((hash) => `'${hash}'`).join(" ");
    return `default-src 'none'; style-src 'unsafe-inline'; font-src ${fontSource}; img-src ${FRAME_IMAGE_SOURCE}; script-src ${scripts}`;
  }
  frameCsp();
  frameCsp([], SRCDOC_FONT_SOURCE);
  const SQL_VIEWS = [
    "v_version_v1",
    "v_tasks_v1",
    "v_task_events_v1",
    "v_usage_v1",
    "v_feed_v1",
    "v_quota_windows_v1",
    "v_routing_v1",
    "v_placements_v1",
    "v_projects_v1",
    "v_repos_v1"
  ];
  const SQL_VIEW_NAME_PATTERN = /^v_[a-z][a-z0-9_]*_v[1-9][0-9]*$/;
  const sqlViewNameSchema = string().regex(SQL_VIEW_NAME_PATTERN, {
    message: "a versioned view name, such as v_usage_v1"
  });
  const SQL_LIMITS = {
    /** UTF-8 bytes of SQL text. */
    textBytes: 4096,
    params: 32,
    /** UTF-8 bytes of one string param. */
    paramBytes: 4096
  };
  function utf8Bytes(text) {
    return new TextEncoder().encode(text).byteLength;
  }
  const sqlParamSchema = union([
    string().refine((value) => utf8Bytes(value) <= SQL_LIMITS.paramBytes, "a param is at most 4 KB"),
    number().finite(),
    _null()
  ]);
  const sqlTextSchema = string().min(1).refine((value) => utf8Bytes(value) <= SQL_LIMITS.textBytes, "a query is at most 4 KB");
  strictObject({
    sql: sqlTextSchema,
    params: array(sqlParamSchema).max(SQL_LIMITS.params).optional()
  });
  strictObject({
    sql: sqlTextSchema,
    params: array(sqlParamSchema).max(SQL_LIMITS.params).optional(),
    views: array(sqlViewNameSchema).max(64)
  });
  const SQL_REFUSAL_CODES = [
    "sql_view_not_declared",
    "sql_not_readonly",
    "sql_invalid",
    "sql_timeout",
    "sql_too_large"
  ];
  const sqlValueSchema = union([string(), number(), _null()]);
  const sqlRowsSchema = object({
    columns: array(string()),
    rows: array(record(string(), sqlValueSchema)),
    truncated: boolean(),
    elapsedMs: number()
  });
  const sqlRefusalSchema = object({
    refused: _enum(SQL_REFUSAL_CODES),
    message: string()
  });
  union([sqlRefusalSchema, sqlRowsSchema]);
  const COMPUTER = {
    many: "computers"
  };
  const KEYBOARD_COMMANDS = {
    // The window's own commands, in the order command search lists them.
    "commands.search": {
      label: "Search commands",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: "k", meta: true }]
    },
    // The way back from wherever focus is, a card's or a panel's frame included.
    "focus.main-message": {
      label: "Go to the main message",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: "l", meta: true }]
    },
    // The card's one field (INF-924): a reply, or words for a choice.
    "focus.card-reply": {
      label: "Go to the card's reply",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: "l", meta: true, shift: true }],
      searchWords: ["anything to add", "comment"]
    },
    // The shown card's own places (docs/keyboard.md, "Cards and frames"):
    // its body to read and answer, and its buttons. No key of their own yet:
    // chosen by name, and a person may give them one.
    "focus.card-body": {
      label: "Go to the card's body",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: []
    },
    // Focus only: a button is pressed by its own key, through the click's checks.
    "focus.card-actions": {
      label: "Go to the card's buttons",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: []
    },
    // The shown card's footer choices (docs/keyboard.md): ⌘1 the default,
    // so the recommended step is always the same key, then the rest from the
    // right edge leftward. A digit with ⌘ never types, so a reply and a card
    // body keep their characters. The button's own click still decides: an
    // unanswered question is not sent, and a pending or disabled button does
    // not run.
    "cards.choice-1": {
      label: "Press the recommended choice",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "close",
      keys: [{ key: "1", meta: true }],
      searchWords: ["card", "button", "default", "first"]
    },
    "cards.choice-2": {
      label: "Press the second choice",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "close",
      keys: [{ key: "2", meta: true }],
      searchWords: ["card", "button"]
    },
    "cards.choice-3": {
      label: "Press the third choice",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "close",
      keys: [{ key: "3", meta: true }],
      searchWords: ["card", "button"]
    },
    "cards.choice-4": {
      label: "Press the fourth choice",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "close",
      keys: [{ key: "4", meta: true }],
      searchWords: ["card", "button"]
    },
    // The window's parts in turn (docs/keyboard.md, "Parts of the window"):
    // F6 as other desktop apps move between their panes. A function key needs
    // no modifier; on a Mac it may need Fn, so it can be changed like any key.
    "regions.next": {
      label: "Go to the next part of the window",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: "F6" }]
    },
    "regions.previous": {
      label: "Go to the previous part of the window",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: "F6", shift: true }]
    },
    "computers.previous": {
      label: "Previous work computers",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: []
    },
    "computers.next": {
      label: "Next work computers",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: []
    },
    // The top bar's project pill (docs/project-focus.md): its row opens with
    // focus on the pills, and focus leaves by name.
    "project-focus.open": {
      label: "Focus on a project",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "view",
      keys: [{ key: "p", meta: true, shift: true }],
      searchWords: ["filter", "project", "pill"]
    },
    "project-focus.clear": {
      label: "Show all projects",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "view",
      keys: [],
      searchWords: ["filter", "focus", "project", "clear"]
    },
    // ⇧⌘[ as a Mac reports it while ⌘ is down (`[` with Shift), and as the
    // shifted character other input reports (`{` with Shift).
    "cards.previous": {
      label: "Show the previous card",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [
        { key: "[", meta: true, shift: true },
        { key: "{", meta: true, shift: true }
      ]
    },
    "cards.next": {
      label: "Show the next card",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [
        { key: "]", meta: true, shift: true },
        { key: "}", meta: true, shift: true }
      ]
    },
    "cards.minimize": {
      label: "Put card aside",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "view",
      keys: [{ key: "m", meta: true, shift: true }]
    },
    "cards.done": {
      label: "Press the note's Done or Got it",
      searchWords: ["card", "note", "answer", "done", "got it"],
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "close",
      keys: []
    },
    // INF-3108: the shown decision's way to say no, the app's Decline or the
    // author's own, chosen by name; ⌘1-⌘4 also reach it by its place.
    "cards.decline": {
      label: "Decline every choice on the card",
      searchWords: ["card", "decline", "no", "not now", "none", "reject"],
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "close",
      keys: []
    },
    "cards.maximize": {
      label: "Maximize or restore card",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "view",
      keys: [],
      searchWords: ["full", "screen", "enlarge", "expand", "bigger"]
    },
    "cards.next-revision": {
      label: "Go to the next revised area",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["changes", "revision", "links"]
    },
    // The shown card's thread folded into the card's foot, or beside it again
    // (docs/card-threads.md, "The shell"): ⌘\ as a sidebar is shown or hidden.
    "cards.thread": {
      label: "Show or hide the card's thread",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: "\\", meta: true }],
      searchWords: ["collapse", "expand", "chat", "replies", "messages"]
    },
    // The shown card's jump down in its thread, while the captain reads above
    // its foot (docs/card-threads.md, "Keeping your place"): chosen by name.
    "cards.thread-new": {
      label: "Go to the thread's new messages",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["jump", "down", "latest", "bottom", "unread", "replies"]
    },
    // The shown task card's tabs (docs/task-card-tabs.md): Info, Cards,
    // Activity (INF-2261), the crewmate's session and the browser's pages,
    // and on a card about a task its way to them (INF-358). No key of their
    // own yet: chosen by name.
    "cards.show-info": {
      label: "Show Info",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "record", "tab", "open"]
    },
    "cards.show-cards": {
      label: "Show Cards",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "record", "tab", "decisions", "notes"]
    },
    "cards.show-activity": {
      label: "Show Activity",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "record", "tab", "timeline", "history"]
    },
    "cards.show-crewmate": {
      label: "Show Crewmate",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "session", "transcript", "tab"]
    },
    "browser.control": {
      label: "Take or return browser control",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["handback", "take", "return", "browser"]
    },
    // The shown task record's Move to a computer (docs/helper.md, "Moving a
    // started task"): opens its picker, which saves nothing until Move.
    "task.move-computer": {
      label: "Move the task to another computer",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["computer", "mac", "machine", "move", "device", "record"]
    },
    // The shown task record's Close as done (INF-3169's plan, piece 3): opens
    // its one confirm, which closes nothing until its own Close as done.
    "task.close-done": {
      label: "Close the task as done",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["done", "finish", "finished", "complete", "close", "record", "task"]
    },
    "cards.show-browser": {
      label: "Show Browser",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "page", "tab"]
    },
    "cards.next-tab": {
      label: "Next tab",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "tab"]
    },
    "cards.previous-tab": {
      label: "Previous tab",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["task", "tab"]
    },
    "settings.open": {
      label: "Open Settings",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [{ key: ",", meta: true }]
    },
    // Chosen by name, and from the app menu's Keyboard Settings…, which no
    // change of keys can take away.
    "settings.keyboard": {
      label: "Open Keyboard settings",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: []
    },
    // Settings → Panels (INF-2344), chosen by name: no default key.
    "settings.panels": {
      label: "Arrange panels",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["rails", "layout", "order", "move", "hide", "show"]
    },
    // The update notice is also reached by name; opening it grants no installation consent.
    "updates.show": {
      label: "Show available update",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["update", "restart", "stable", "alpha"]
    },
    // INF-2245: the update notice's Update later, chosen by name while an
    // update saves the crew's work; a person may give it a key.
    "updates.later": {
      label: "Update later",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["update", "later", "cancel", "saving", "work"]
    },
    // INF-2073: Settings → General's Check for updates, chosen by name; a person may give it a key.
    "updates.check": {
      label: "Check for updates",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["update", "version", "release", "new"]
    },
    // The newest release note again (docs/release-notes.md "Reading a note
    // again"): chosen by name, and from the Help menu's What's New, like
    // Keyboard settings; a person may give it a key.
    "whats-new.show": {
      label: "Show what's new",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["release", "notes", "changes", "version"]
    },
    // The first mate's newest reply, whole, as a note at the front
    // (docs/composer.md "The reply note"): chosen by name, so it opens after
    // the line above the input has faded too.
    "firstmate.reply": {
      label: "Open the first mate's reply",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["answer", "message", "note", "last"]
    },
    "settings.runbooks": {
      label: "Open Runbooks",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["guidance", "skills", "instructions"]
    },
    "runbooks.open-folder": {
      label: "Open your runbooks folder",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["directory", "guidance", "customize"]
    },
    // Settings → Usage (docs/usage.md), chosen by name: it has no default key.
    "settings.usage": {
      label: "Open Usage",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["tokens", "models", "cost", "dollars"]
    },
    // Settings → Automation (docs/automation.md), chosen by name: no default key.
    "settings.automation": {
      label: "Open Automation",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["schedule", "scheduled", "recurring", "reminder", "pause"]
    },
    // Settings → Integrations (docs/integrations.md), chosen by name: no default key.
    "settings.integrations": {
      label: "Open Integrations",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["github", "connection", "connect", "sign in"]
    },
    "settings.secrets": {
      label: "Open Secrets",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["secret", "key", "approval", "recovery"],
      section: "secrets"
    },
    // Every running automation paused at once, as Settings → Automation's
    // Pause all does; it opens Automation so the change is seen. No default key.
    "automation.pause-all": {
      label: "Pause all automations",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["schedule", "scheduled", "recurring", "stop"]
    },
    // Tokens or estimated dollars, everywhere in Usage at once; it opens
    // Usage, so the switch is seen, and the core remembers the choice.
    "usage.unit": {
      label: "Switch Usage units",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "view",
      keys: [],
      searchWords: ["tokens", "cost", "dollars", "estimate"]
    },
    // Every account's allowance read again, as the spent-allowance card's
    // Recheck allowance and Subscriptions' Refresh do: a login switched
    // elsewhere is read first (docs/quota.md "A changed login"). No default key.
    "allowance.recheck": {
      label: "Recheck allowance",
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "view",
      keys: [],
      searchWords: ["quota", "refresh", "usage", "limit", "account", "switch"]
    },
    // This Mac's own SSH connections to the Macs it added by their address,
    // each it stopped trying tried once more (docs/devices.md, "Through the
    // home's SSH"); chosen by name, and only where Devices shows.
    "devices.try-again": {
      label: `Try again to reach your ${COMPUTER.many}`,
      scope: "window",
      runs: "shell",
      repeat: false,
      risk: "navigate",
      keys: [],
      searchWords: ["devices", "ssh", "reconnect", "connect", "macs"],
      section: "devices"
    },
    // Control too, as the window always took it; the menu shows the first.
    "size.larger": {
      label: "Make everything larger",
      scope: "window",
      runs: "main",
      repeat: true,
      risk: "view",
      keys: [
        { key: "+", meta: true },
        { key: "=", meta: true },
        { key: "+", ctrl: true },
        { key: "=", ctrl: true }
      ]
    },
    "size.smaller": {
      label: "Make everything smaller",
      scope: "window",
      runs: "main",
      repeat: true,
      risk: "view",
      keys: [
        { key: "-", meta: true },
        { key: "-", ctrl: true }
      ]
    },
    "size.reset": {
      label: "Return to the usual size",
      scope: "window",
      runs: "main",
      repeat: true,
      risk: "view",
      keys: [
        { key: "0", meta: true },
        { key: "0", ctrl: true }
      ]
    },
    "message.delete-to-line-start": {
      label: "Delete back to the start of the line",
      scope: "message-field",
      repeat: true,
      risk: "edit",
      keys: [{ key: "u", ctrl: true }]
    },
    "message.delete-to-line-end": {
      label: "Delete to the end of the line",
      scope: "message-field",
      repeat: true,
      risk: "edit",
      keys: [{ key: "k", ctrl: true }]
    },
    "message.delete-word-before": {
      label: "Delete the word before the cursor",
      scope: "message-field",
      repeat: true,
      risk: "edit",
      keys: [{ key: "w", ctrl: true }]
    },
    "message.put-back-deleted": {
      label: "Put back what was last deleted",
      scope: "message-field",
      repeat: true,
      risk: "edit",
      keys: [{ key: "y", ctrl: true }]
    },
    "message.recall": {
      label: "Bring back the last message sent",
      scope: "main-message",
      repeat: false,
      risk: "edit",
      keys: [{ key: "ArrowUp" }, { key: "p", ctrl: true }]
    }
  };
  function isWindowCommand(id) {
    return KEYBOARD_COMMANDS[id].scope === "window";
  }
  function isShellCommand(id) {
    const command = KEYBOARD_COMMANDS[id];
    return command.runs === "shell";
  }
  const COMMAND_IDS = Object.keys(KEYBOARD_COMMANDS);
  COMMAND_IDS.filter(isShellCommand);
  COMMAND_IDS.filter(
    (id) => isWindowCommand(id) && !isShellCommand(id)
  );
  function systemChord(chord, system) {
    if (system === "mac" || !chord.meta && !chord.ctrl) return chord;
    if (chord.ctrl) return null;
    return {
      key: chord.key,
      ctrl: true,
      ...chord.alt ? { alt: true } : {},
      ...chord.shift ? { shift: true } : {}
    };
  }
  function systemKeys(keys, system) {
    if (system === "mac") return keys;
    const pressed2 = [];
    for (const binding of keys) {
      const first = systemChord(binding, system);
      const second = binding.second ? systemChord(binding.second, system) : void 0;
      if (!first || second === null) continue;
      const next2 = second ? { ...first, second } : first;
      if (!pressed2.some((kept) => JSON.stringify(kept) === JSON.stringify(next2))) pressed2.push(next2);
    }
    return pressed2;
  }
  function catalogKeys(id, system = "mac") {
    return systemKeys(KEYBOARD_COMMANDS[id].keys, system);
  }
  function catalogBindings(system) {
    return Object.fromEntries(
      COMMAND_IDS.map((id) => [id, catalogKeys(id, system)])
    );
  }
  catalogBindings("mac");
  const PANEL_CARD_WIDTHS = ["regular", "wide", "full"];
  const panelCardWidthSchema = _enum(PANEL_CARD_WIDTHS);
  const PANEL_CARD_HEIGHTS = ["content", "fill"];
  const panelCardHeightSchema = _enum(PANEL_CARD_HEIGHTS);
  const PANEL_HEADER_ICONS = [
    "open",
    "search",
    "add",
    "list",
    "note",
    "filter",
    "clock",
    "chart"
  ];
  const panelHeaderIconSchema = _enum(PANEL_HEADER_ICONS);
  const PANEL_HEADER_MAX = 3;
  const PANEL_COMMANDS_MAX = 16;
  const PANEL_CARD_VIEWS_MAX = 16;
  const PANEL_CARD_DATA_MAX_BYTES = 3072;
  const PANEL_CARD_KEPT_MAX_BYTES = 4096;
  const PANEL_NAME_PATTERN = /^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/;
  const panelNameSchema = string().min(1).max(32).regex(PANEL_NAME_PATTERN, "kebab-case");
  const PANEL_CARD_ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9_.:-]{0,63}$/;
  const panelCardIdSchema = string().regex(PANEL_CARD_ID_PATTERN, "a plain id");
  const panelCardTitleSchema = string().min(1).max(80);
  const storeValueSchema$1 = lazy(
    () => union([
      _null(),
      boolean(),
      number().finite(),
      string(),
      array(storeValueSchema$1),
      record(string(), storeValueSchema$1)
    ])
  );
  const panelCardDataSchema = storeValueSchema$1.refine(
    (value) => JSON.stringify(value).length <= PANEL_CARD_DATA_MAX_BYTES,
    `a card's data is at most ${PANEL_CARD_DATA_MAX_BYTES} bytes of JSON`
  );
  storeValueSchema$1.refine(
    (value) => new TextEncoder().encode(JSON.stringify(value)).byteLength <= PANEL_CARD_KEPT_MAX_BYTES,
    `a card keeps at most ${PANEL_CARD_KEPT_MAX_BYTES} bytes of JSON`
  );
  const panelCardDeclarationSchema = strictObject({
    view: panelNameSchema,
    title: panelCardTitleSchema,
    width: panelCardWidthSchema.optional(),
    height: panelCardHeightSchema.optional(),
    data: panelCardDataSchema.optional()
  });
  const panelHeaderButtonSchema = strictObject({
    id: panelNameSchema,
    icon: panelHeaderIconSchema,
    label: string().min(1).max(40),
    emits: panelNameSchema.optional(),
    data: panelCardDataSchema.optional()
  });
  const PANEL_COMMAND_WORDS_MAX = 8;
  const PANEL_COMMAND_WORD_MAX = 24;
  const panelCommandDeclarationSchema = strictObject({
    id: panelNameSchema,
    label: string().min(1).max(60),
    emits: panelNameSchema.optional(),
    presses: panelNameSchema.optional(),
    data: panelCardDataSchema.optional(),
    key: string().min(1).max(12).refine((key) => parseSuggestedKey(key) !== null, "a key as a Mac writes it, such as ⌘B").optional(),
    words: array(string().min(1).max(PANEL_COMMAND_WORD_MAX).regex(/^\S+$/, "one word")).max(PANEL_COMMAND_WORDS_MAX).optional()
  }).refine(
    (command) => command.emits === void 0 !== (command.presses === void 0),
    "a command either emits a card or presses a header button"
  );
  strictObject({
    id: panelCardIdSchema.optional(),
    view: panelNameSchema,
    title: panelCardTitleSchema,
    width: panelCardWidthSchema.optional(),
    height: panelCardHeightSchema.optional(),
    data: panelCardDataSchema.optional()
  });
  const panelCardsDeclarationSchema = record(panelNameSchema, panelCardDeclarationSchema).refine(
    (cards) => Object.keys(cards).length <= PANEL_CARD_VIEWS_MAX,
    `at most ${PANEL_CARD_VIEWS_MAX} named cards`
  );
  const panelHeaderSchema = array(panelHeaderButtonSchema).max(PANEL_HEADER_MAX);
  const panelCommandsSchema = array(panelCommandDeclarationSchema).max(PANEL_COMMANDS_MAX);
  const MODIFIER_GLYPHS = {
    "⌃": "ctrl",
    "⌥": "alt",
    "⇧": "shift",
    "⌘": "meta"
  };
  function parseSuggestedKey(text) {
    const chord = { key: "" };
    let rest = text;
    while (rest.length > 0) {
      const modifier = MODIFIER_GLYPHS[rest[0]];
      if (!modifier) break;
      if (chord[modifier]) return null;
      chord[modifier] = true;
      rest = rest.slice(1);
    }
    if (/^F([1-9]|1[0-9]|2[0-4])$/.test(rest)) return { ...chord, key: rest };
    if ([...rest].length !== 1 || /\s/.test(rest)) return null;
    return { ...chord, key: /^[A-Za-z]$/.test(rest) ? rest.toLowerCase() : rest };
  }
  const KEBAB_ID = /^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/;
  const pluginIdSchema = string().min(2).max(64).regex(KEBAB_ID, "kebab-case id");
  const contributionIdSchema = string().min(1).max(64).regex(KEBAB_ID, "kebab-case id");
  const SEMVER = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/;
  const cardChromeSchema = _enum(["decision", "note", "attention", "record"]);
  const cardKindEntrySchema = strictObject({
    /** The presentation this describes (`cardPresentation` in cards.ts), or a plugin's own. */
    kind: contributionIdSchema,
    chrome: cardChromeSchema,
    body: strictObject({
      /**
       * Legacy compatibility field, accepted but no longer read: `plain` showed the body as linked
       * text (a report mid-flight), `html` renders it in the frame as usual.
       */
      streaming: _enum(["plain", "html"])
    })
  });
  const settingsSectionEntrySchema = strictObject({
    id: contributionIdSchema,
    /** Tab label, sentence case. */
    label: string().min(1).max(24),
    /** Lower sorts first; ties break on id. */
    order: number().int().min(0).max(1e3),
    /** Settings is one centred column. Default is the Intelligence wide shell. */
    width: _enum(["standard", "wide"]).default("wide")
  });
  const railSideSchema = _enum(["left", "right"]);
  const railYSchema = _enum(["top", "bottom"]);
  const sidePanelPlacementSchema = strictObject({
    x: railSideSchema,
    y: railYSchema
  });
  const sidePanelSizeSchema = _enum(["content", "fill"]);
  const sidePanelEntrySchema = strictObject({
    id: contributionIdSchema,
    /** Host-rendered panel title, sentence case. */
    title: string().min(1).max(40),
    /** A preference; the host decides final placement (D5). */
    preferredPlacement: sidePanelPlacementSchema,
    order: number().int().min(0).max(1e3),
    size: sidePanelSizeSchema.default("content"),
    /**
     * The panel reads newest last. When the window gives it less room than its
     * page asks, the host shows the page's end, so the newest line stays in
     * sight without the page asking the window to scroll.
     */
    newestLast: boolean().default(false),
    /**
     * The panel's cards on the main card stack (docs/ui-plugins.md, "A
     * panel's cards"): its card views, the cards its header buttons and
     * commands put up by name, the buttons the host draws in its header, and
     * the commands it adds to command search. Data the host reads and draws
     * as its own chrome; a panel without them has none.
     */
    cardViews: array(string().regex(PANEL_NAME_PATTERN)).max(PANEL_CARD_VIEWS_MAX).optional(),
    cards: panelCardsDeclarationSchema.optional(),
    header: panelHeaderSchema.optional(),
    commands: panelCommandsSchema.optional()
  });
  function uniqueIds(items, id, ctx, slot) {
    const seen = /* @__PURE__ */ new Set();
    for (const item of items) {
      const key = id(item);
      if (seen.has(key)) {
        ctx.addIssue({ code: "custom", message: `duplicate ${slot} id "${key}"` });
      }
      seen.add(key);
    }
  }
  const contributionsSchema = strictObject({
    cardKinds: array(cardKindEntrySchema).default([]).superRefine((items, ctx) => uniqueIds(items, (item) => item.kind, ctx, "card-kind")),
    settingsSections: array(settingsSectionEntrySchema).default([]).superRefine((items, ctx) => uniqueIds(items, (item) => item.id, ctx, "settings-section")),
    sidePanels: array(sidePanelEntrySchema).default([]).superRefine((items, ctx) => uniqueIds(items, (item) => item.id, ctx, "side-panel"))
  });
  const STORAGE_KV_MAX_BYTES = 1048576;
  function retiredGrantWords(key) {
    return `"${key}" is retired: a panel reaches a service outside your projects only through an integration. Name the connection, its actions and why under "integrations".`;
  }
  const integrationWordSchema = string().min(1).max(64).regex(/^[^\s/][^/]*$/, "a name with no slash");
  const eventWordSchema = string().min(1).max(48).regex(/^[^\s/][^/]*$/, "a name with no slash");
  const panelIntegrationUseSchema = strictObject({
    integration: integrationWordSchema,
    actions: array(integrationWordSchema).optional(),
    events: array(eventWordSchema).optional(),
    why: string().trim().min(1)
  }).superRefine((use, ctx) => {
    if (!use.actions?.length && !use.events?.length)
      ctx.addIssue({
        code: "custom",
        message: `"${use.integration}" names no action and no event`
      });
  });
  const panelIntegrationsSchema = array(panelIntegrationUseSchema).superRefine((uses, ctx) => {
    const seen = /* @__PURE__ */ new Set();
    for (const use of uses) {
      const key = use.integration.trim().toLowerCase();
      if (seen.has(key))
        ctx.addIssue({ code: "custom", message: `"${use.integration}" is named twice` });
      seen.add(key);
    }
  });
  const readNameSchema = string().min(1).max(64).regex(/^[a-z][a-z0-9-]*(?:\.[a-z][a-z0-9-]*)*$/, "dotted read-catalog name");
  const capabilitiesSchema = strictObject({
    /** Retired: refused with `retiredGrantWords`. */
    net: never({ message: retiredGrantWords("net") }).optional(),
    /** Retired: refused with `retiredGrantWords`. */
    secrets: never({ message: retiredGrantWords("secrets") }).optional(),
    /** The integrations it uses, each under that action's own rule in Settings. */
    integrations: panelIntegrationsSchema.optional(),
    storage: strictObject({
      kv: strictObject({
        maxBytes: number().int().positive().max(STORAGE_KV_MAX_BYTES)
      })
    }).optional(),
    /** Read-catalog entry names (phase 1 names the catalog; the host validates). */
    reads: array(readNameSchema).max(64).optional(),
    /**
     * The views of the app's record the plugin may query through the `sql`
     * read, by their exact versioned names (`v_usage_v1`; src/shared/sql.ts).
     * Naming at least one is what serves the read; `reads: ["sql"]` is not.
     */
    sql: array(sqlViewNameSchema).max(SQL_VIEWS.length).optional(),
    /**
     * It moves the captain's tasks - start, stop, continue, drop, queue,
     * unqueue - each only on his click or key in it (docs/ui-plugins.md, "A
     * panel's cards"). Never merge or discard.
     */
    moves: literal(true).optional()
  });
  strictObject({
    id: pluginIdSchema,
    /** Human name; the host renders it as the attribution on every contribution. */
    name: string().min(1).max(40),
    version: string().regex(SEMVER, "semver"),
    contributes: contributionsSchema,
    capabilities: capabilitiesSchema
  });
  const PERSONAL_ID_PATTERN = /^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/;
  const PERSONAL_ID_MAX_LENGTH = 48;
  const personalIdSchema = string().min(2).max(PERSONAL_ID_MAX_LENGTH).regex(PERSONAL_ID_PATTERN);
  const PLUGIN_SOURCES = ["yours", "installed"];
  const PERSONAL_STORE_KEY_MAX_LENGTH = 128;
  const PANEL_READ_NAMES = [
    "computers.resources",
    "quota.snapshot",
    "tasks.board",
    "tasks.detail",
    "tasks.search",
    "feed.recent",
    "forge.changes",
    "automation.list",
    "knowledge.collections",
    "knowledge.graph",
    "knowledge.concepts",
    "knowledge.directions",
    "knowledge.findings",
    "knowledge.entry",
    "knowledge.direction"
  ];
  const panelReadNameSchema = _enum(PANEL_READ_NAMES);
  const storeValueSchema = lazy(
    () => union([
      _null(),
      boolean(),
      number().finite(),
      string(),
      array(storeValueSchema),
      record(string(), storeValueSchema)
    ])
  );
  const storeEntrySchema = object({
    key: string(),
    value: storeValueSchema,
    updatedAt: number()
  });
  const personalPresenceSchema = union([
    strictObject({ always: literal(true) }),
    strictObject({
      store: string().min(1).max(PERSONAL_STORE_KEY_MAX_LENGTH),
      when: literal("nonEmpty")
    }),
    strictObject({ code: literal(true) })
  ]);
  const personalPlacementSchema = strictObject({
    x: _enum(["left", "right"]),
    y: _enum(["top", "bottom"])
  });
  strictObject({
    api: union([literal(1), literal(2)], {
      message: "this panel is written for a version of the panel API this app does not serve"
    }).optional(),
    name: string().min(1).max(40).optional(),
    version: string().regex(/^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$/, "semver").optional(),
    title: string().min(1).max(40).optional(),
    placement: personalPlacementSchema.optional(),
    order: number().int().min(0).max(1e3).optional(),
    size: _enum(["content", "fill"]).optional(),
    /** Reads newest last: the window keeps the panel's end in sight when it gives the panel less room than its page asks. */
    newestLast: boolean().optional(),
    presence: personalPresenceSchema.optional(),
    cards: panelCardsDeclarationSchema.optional(),
    header: panelHeaderSchema.optional(),
    commands: panelCommandsSchema.optional(),
    reads: array(panelReadNameSchema).max(PANEL_READ_NAMES.length).optional(),
    moves: literal(true).optional(),
    sql: array(sqlViewNameSchema).max(64).optional(),
    integrations: panelIntegrationsSchema.optional(),
    /** Retired: a panel reaches a service through an integration (`retiredGrantWords`). */
    net: never({ message: retiredGrantWords("net") }).optional(),
    /** Retired, with `net`. */
    secrets: never({ message: retiredGrantWords("secrets") }).optional(),
    storage: strictObject({
      kv: strictObject({ maxBytes: number().int().positive().max(STORAGE_KV_MAX_BYTES) })
    }).optional(),
    origin: strictObject({ taskId: string().min(1).max(64).optional() }).optional()
  });
  ({
    reads: new Set(PANEL_READ_NAMES),
    sql: new Set(SQL_VIEWS)
  });
  const personalErrorSchema = object({
    /** Which file refused: the manifest, the panel graph, or the server graph. */
    stage: _enum(["manifest", "panel", "server"]),
    /** Names the offending path, and the import when one is refused. */
    message: string()
  });
  const personalExtensionViewSchema = object({
    id: personalIdSchema,
    /** Where it came from, stamped by the host (Phase A item 1). */
    source: _enum(PLUGIN_SOURCES),
    /** An installed plugin's `name`: the attribution on its header. Null for the captain's own. */
    by: string().min(1).max(40).nullable(),
    title: string().min(1).max(40),
    placement: personalPlacementSchema,
    order: number().int(),
    size: _enum(["content", "fill"]),
    newestLast: boolean().optional(),
    /** The presence rule's verdict right now; the renderer shows the panel only while true. */
    present: boolean(),
    /**
     * Its presence is its own code's to decide (`{ "code": true }`): its page
     * runs, and it is on its rail only while it says so (`rail.show`).
     */
    ownPresence: boolean(),
    /** It may move the captain's tasks: its manifest asks, and for an added one he agreed. */
    moves: boolean(),
    /** A task on this extension is active: the header shows the running dot. */
    running: boolean(),
    /** The app's own reads the manifest declared; the panel is served these and no other. */
    reads: array(panelReadNameSchema),
    /**
     * The views of the app's record the manifest declared (`sql`), every one
     * published by this version - a manifest naming one it does not publish is
     * an error and mounts nothing. The panel's queries reach these and no other.
     */
    sql: array(sqlViewNameSchema),
    /**
     * Always null: it named a compiled panel the window imported in-process,
     * which no panel is any more (INF-2205 piece C). Kept so an older reader
     * still parses the snapshot; it reads `frame`.
     */
    panel: object({ url: string(), version: string() }).nullable(),
    /**
     * The compiled panel the frame realm draws contained (Phase A item 4;
     * INF-2205 piece C), whatever its source: the version of the graph the
     * frame will load. Null when it has no panel, or its panel failed.
     */
    frame: object({ version: string() }).nullable(),
    /**
     * Its card views (`cards/<view>.tsx`), compiled beside its panel: the
     * views `cards.emit` may name. Empty for a panel with none.
     */
    cardViews: array(string().regex(PANEL_NAME_PATTERN)).max(PANEL_CARD_VIEWS_MAX),
    /** The cards its header buttons and commands put up, by name, as its manifest declares them. */
    cards: panelCardsDeclarationSchema,
    /** The buttons the app draws in its header. */
    header: panelHeaderSchema,
    /** The commands it adds to command search. */
    commands: panelCommandsSchema,
    /** What `server.ts` exported, after clamping, or null when there is none (or it failed). */
    server: object({
      actions: array(string()),
      background: array(object({ id: string(), everyMs: number() }))
    }).nullable(),
    error: personalErrorSchema.nullable(),
    /**
     * The app stopped its background work (INF-2205 piece B): it went silent
     * or ended on its own. The stop holds across reloads and restarts until
     * the captain's Retry; absent while nothing is stopped.
     */
    stopped: object({
      reason: _enum(["unresponsive", "exited"]),
      /** When it was noticed, ISO wall time. */
      at: string(),
      /** The code version that was stopped. */
      version: string()
    }).optional(),
    /**
     * The app refused its `server.ts` before it ran, because it is written for
     * a panel API this version no longer serves (INF-2470). The panel still
     * draws; the window says its background work is paused, with Update panel.
     * Absent while nothing is refused.
     */
    paused: object({
      /** The panel API its manifest names; 1 when it names none. */
      api: number().int().min(1),
      /** The panel APIs this version serves a `server.ts`. */
      serves: array(number().int().min(1)),
      /** The captain pressed Update panel and the first mate was told, for this code. */
      asked: boolean()
    }).optional(),
    /**
     * Its integration calls waiting on the captain or turned down
     * (docs/integrations.md, "Panels"): one line each, which the window draws
     * with Ask again. Absent while none is.
     */
    integrationAsks: array(
      object({
        /** The integration's id, as Ask again names it. */
        integration: string().min(1).max(200),
        /** Its name when asked. */
        place: string().min(1).max(200),
        action: string().min(1).max(200),
        /** The action's few words, such as "Read from GitHub". */
        label: string().min(1).max(200),
        /** Its approval card is up, or the captain chose Not now. */
        state: _enum(["asking", "declined"])
      })
    ).optional()
  });
  object({
    extensions: array(personalExtensionViewSchema),
    /**
     * The captain's own panels as the crewmates building them have them now
     * (docs/personal-panels.md, "Built apart"): the working files, run apart
     * from the rails, which keep each panel's last commit until the build's
     * report. Absent while nothing is being built.
     */
    drafts: array(personalExtensionViewSchema).optional()
  });
  object({
    extensionId: personalIdSchema,
    key: string(),
    /** The change was to the store of the extension's draft, never its panel's own. */
    draft: literal(true).optional()
  });
  const storeKeySchema = string().min(1).max(PERSONAL_STORE_KEY_MAX_LENGTH);
  const draftFlag = literal(true).optional();
  discriminatedUnion("op", [
    object({
      op: literal("get"),
      extensionId: personalIdSchema,
      key: storeKeySchema,
      draft: draftFlag
    }),
    object({
      op: literal("set"),
      extensionId: personalIdSchema,
      key: storeKeySchema,
      value: storeValueSchema,
      draft: draftFlag
    }),
    object({
      op: literal("delete"),
      extensionId: personalIdSchema,
      key: storeKeySchema,
      draft: draftFlag
    }),
    object({
      op: literal("list"),
      extensionId: personalIdSchema,
      prefix: string().max(PERSONAL_STORE_KEY_MAX_LENGTH).optional(),
      draft: draftFlag
    })
  ]);
  object({
    /** `get`: the value, absent when the key is unset. */
    value: storeValueSchema.optional(),
    /** `list`: the entries under the prefix, key order. */
    entries: array(storeEntrySchema).optional()
  });
  object({ draft: draftFlag });
  discriminatedUnion("op", [
    object({ op: literal("list") }),
    object({ op: literal("show"), name: string().min(1).max(200) }),
    object({
      op: literal("call"),
      name: string().min(1).max(200),
      action: string().min(1).max(200),
      input: unknown().optional()
    })
  ]);
  union([
    object({ text: string(), refused: _enum(["refused", "invalid"]).optional() }),
    array(record(string(), unknown())),
    record(string(), unknown())
  ]);
  union([
    object({ ok: literal(true), result: unknown() }),
    object({ ok: literal(false), error: string() })
  ]);
  const BUILTIN_FRAME_PANELS = ["activity", "automation", "knowledge", "now"];
  const FRAME_TEMPLATE_MAX_BYTES = 524288;
  function withoutClosingTag(tag) {
    const closing = new RegExp(`</${tag}`, "i");
    return (text) => !closing.test(text);
  }
  const frameTemplateSchema = strictObject({
    /** Body markup. Scripts inside it never run: only `script` is hash-pinned. */
    html: string().max(FRAME_TEMPLATE_MAX_BYTES).refine(withoutClosingTag("body"), "a </body> tag"),
    /** The template's script, run inside the frame after the markup is parsed. */
    script: string().min(1).max(FRAME_TEMPLATE_MAX_BYTES).refine(withoutClosingTag("script"), "a <\/script> tag").optional()
  });
  const cardFrameTemplateSchema = strictObject({
    html: string().max(FRAME_TEMPLATE_MAX_BYTES)
  });
  const frameThemeSchema = _enum(["dark", "light"]);
  const frameMountBaseSchema = strictObject({
    /** Names the frame in the host's chrome and in its document title. */
    title: string().min(1).max(120),
    theme: frameThemeSchema,
    /** The design system's frame stylesheet: tokens, fonts, base rules. */
    style: string().max(FRAME_TEMPLATE_MAX_BYTES).refine(withoutClosingTag("style"), "a </style> tag")
  });
  const pluginFrameMountRequestSchema = frameMountBaseSchema.extend({
    template: frameTemplateSchema,
    kind: _undefined().optional()
  });
  const cardFrameMountRequestSchema = frameMountBaseSchema.extend({
    template: cardFrameTemplateSchema,
    /**
     * An agent-authored card body whose own inline script runs (WI-16). It is
     * served from a host of its own, `app-frame://card-<id>/`, so the browser
     * gives it a site - and a renderer process - of its own.
     */
    kind: literal("card")
  });
  const panelModuleSchema = discriminatedUnion("source", [
    strictObject({
      source: literal("builtin"),
      id: _enum(BUILTIN_FRAME_PANELS),
      view: string().regex(PANEL_NAME_PATTERN).optional()
    }),
    strictObject({
      source: literal("installed"),
      id: personalIdSchema,
      /** The compiled graph's content hash (the compiler's 16 hex). */
      version: string().regex(/^[0-9a-f]{16}$/),
      /**
       * One of its card views (`cards/<view>.tsx`) instead of its panel: the
       * document draws that card for the stack (docs/ui-plugins.md, "A
       * panel's cards"), from the same compiled graph.
       */
      view: string().regex(PANEL_NAME_PATTERN).optional()
    }),
    strictObject({
      /**
       * One of the captain's own panels (INF-2205 piece C): drawn here like
       * any other, never in the app's own window. The shell reads its compiled
       * graph out of the personal compile cache, asked of the core for exactly
       * this version - the panel on its rail, or its draft (`draft`) while a
       * crewmate builds it.
       */
      source: literal("personal"),
      id: personalIdSchema,
      version: string().regex(/^[0-9a-f]{16}$/),
      draft: literal(true).optional(),
      view: string().regex(PANEL_NAME_PATTERN).optional()
    })
  ]);
  const panelFrameConfigSchema = strictObject({
    id: string().min(1).max(64).regex(/^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$/),
    reads: array(_enum(PANEL_READ_NAMES)).max(PANEL_READ_NAMES.length),
    sql: array(sqlViewNameSchema).max(64),
    /**
     * Set when the document draws one of the panel's cards: the card's id,
     * which the runtime hands the view as `card.id`. Its data is pushed as
     * view state, so a revised card is heard without a new document.
     */
    card: strictObject({ id: panelCardIdSchema }).optional(),
    /**
     * The captain agreed it may move his tasks: the runtime hands it
     * `tasks`, whose one action the host declared for this mount alone.
     */
    moves: boolean().optional(),
    /**
     * The panel may have background work of its own (`server.ts`, the
     * captain's own panels only): the runtime hands it an `invoke` that asks
     * the host's `server.invoke` action, which the host declared for this
     * mount alone. Absent, `invoke` rejects at once.
     */
    server: boolean().optional()
  });
  const panelFrameMountRequestSchema = frameMountBaseSchema.extend({
    /**
     * A panel written in the plugin shape, drawn in the frame realm: the shell
     * serves the lib and the panel's modules to a document of its own at
     * `app-frame://panel-<id>/`.
     */
    kind: literal("panel"),
    panel: panelModuleSchema,
    config: panelFrameConfigSchema
  });
  union([
    cardFrameMountRequestSchema,
    panelFrameMountRequestSchema,
    pluginFrameMountRequestSchema
  ]);
  object({
    mountId: string().min(1).max(64),
    /** Where the iframe loads the document from. */
    url: string().startsWith(`${APP_FRAME_SCHEME}://`)
  });
  function frameFontUrl(file) {
    return `${APP_FRAME_SCHEME}://fonts/${file}`;
  }
  function escapeAttribute(text) {
    return text.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");
  }
  function buildFrameDocument(parts) {
    const theme = escapeAttribute(parts.theme);
    return [
      "<!doctype html>",
      `<html data-theme="${theme}"${parts.held ? " data-inf-held" : ""}>`,
      "<head>",
      `<meta http-equiv="Content-Security-Policy" content="${escapeAttribute(parts.csp)}">`,
      '<meta charset="utf-8">',
      ...parts.title ? [`<title>${escapeAttribute(parts.title)}</title>`] : [],
      `<style>${parts.style}</style>`,
      `<script>${FRAME_BRIDGE_SCRIPT}<\/script>`,
      "</head>",
      `<body data-theme="${theme}">`,
      parts.html,
      ...parts.script ? [`<script>${parts.script}<\/script>`] : [],
      "</body>",
      "</html>"
    ].join("\n");
  }
  const URL_RE = /https?:\/\/[^\s<>"'`]+/gi;
  function unmatchedCloser(value, open, close) {
    let depth = 0;
    for (const char of value) {
      if (char === open) depth += 1;
      else if (char === close) depth -= 1;
    }
    return depth < 0;
  }
  function trimTrailingUrlPunctuation(raw) {
    let url = raw;
    let trailing = "";
    while (url.length > 0) {
      const last = url[url.length - 1];
      if (!last) break;
      const strip = /[.,;:!?']/.test(last) || last === ")" && unmatchedCloser(url, "(", ")") || last === "]" && unmatchedCloser(url, "[", "]") || last === "}" && unmatchedCloser(url, "{", "}");
      if (!strip) break;
      url = url.slice(0, -1);
      trailing = last + trailing;
    }
    return { url, trailing };
  }
  function isHttpUrl(value) {
    try {
      const parsed = new URL(value);
      return parsed.protocol === "http:" || parsed.protocol === "https:";
    } catch {
      return false;
    }
  }
  function isSafeCardHref(value) {
    try {
      const url = new URL(value);
      if (url.protocol === "https:") return true;
      if (url.protocol === "http:") {
        const host = url.hostname.toLowerCase();
        return host === "localhost" || host.endsWith(".localhost") || host === "127.0.0.1" || host === "::1" || host === "[::1]";
      }
      return false;
    } catch {
      return false;
    }
  }
  function splitCardBodyUrls(body) {
    const parts = [];
    let cursor = 0;
    for (const match of body.matchAll(URL_RE)) {
      const start = match.index ?? 0;
      const { url } = trimTrailingUrlPunctuation(match[0]);
      if (!url || !isHttpUrl(url)) continue;
      if (start > cursor) {
        parts.push({ type: "text", value: body.slice(cursor, start) });
      }
      parts.push({ type: "url", value: url });
      cursor = start + url.length;
    }
    if (cursor < body.length) {
      parts.push({ type: "text", value: body.slice(cursor) });
    }
    return parts;
  }
  const decodeMap = /* @__PURE__ */ new Map([
    [0, 65533],
    // C1 Unicode control character reference replacements
    [128, 8364],
    [130, 8218],
    [131, 402],
    [132, 8222],
    [133, 8230],
    [134, 8224],
    [135, 8225],
    [136, 710],
    [137, 8240],
    [138, 352],
    [139, 8249],
    [140, 338],
    [142, 381],
    [145, 8216],
    [146, 8217],
    [147, 8220],
    [148, 8221],
    [149, 8226],
    [150, 8211],
    [151, 8212],
    [152, 732],
    [153, 8482],
    [154, 353],
    [155, 8250],
    [156, 339],
    [158, 382],
    [159, 376]
  ]);
  function replaceCodePoint(codePoint) {
    if (codePoint >= 55296 && codePoint <= 57343 || codePoint > 1114111) {
      return 65533;
    }
    return decodeMap.get(codePoint) ?? codePoint;
  }
  function decodeBase64(input2) {
    const binary = atob(input2);
    const evenLength = binary.length & -2;
    const out = new Uint16Array(evenLength / 2);
    for (let index = 0, outIndex = 0; index < evenLength; index += 2) {
      const lo = binary.charCodeAt(index);
      const hi = binary.charCodeAt(index + 1);
      out[outIndex++] = lo | hi << 8;
    }
    return out;
  }
  const htmlDecodeTree = /* @__PURE__ */ decodeBase64("QR08ALkAAgH6AYsDNQR2BO0EPgXZBQEGLAbdBxMISQrvCmQLfQurDKQNLw4fD4YPpA+6D/IPAAAAAAAAAAAAAAAAKhBMEY8TmxUWF2EYLBkxGuAa3RsJHDscWR8YIC8jSCSIJcMl6ie3Ku8rEC0CLjoupS7kLgAIRU1hYmNmZ2xtbm9wcnN0dVQAWgBeAGUAaQBzAHcAfgCBAIQAhwCSAJoAoACsALMAbABpAGcAO4DGAMZAUAA7gCYAJkBjAHUAdABlADuAwQDBQHIiZXZlAAJhAAFpeW0AcgByAGMAO4DCAMJAEGRyAADgNdgE3XIAYQB2AGUAO4DAAMBA8CFoYZFj4SFjcgBhZAAAoFMqAAFncIsAjgBvAG4ABGFmAADgNdg43fAlbHlGdW5jdGlvbgCgYSBpAG4AZwA7gMUAxUAAAWNzpACoAHIAAOA12Jzc6SFnbgCgVCJpAGwAZABlADuAwwDDQG0AbAA7gMQAxEAABGFjZWZvcnN1xQDYANoA7QDxAPYA+QD8AAABY3LJAM8AayNzbGFzaAAAoBYidgHTANUAAKDnKmUAZAAAoAYjeQARZIABY3J0AOAA5QDrAGEidXNlAACgNSLuI291bGxpcwCgLCFhAJJjcgAA4DXYBd1wAGYAAOA12Dnd5SF2ZdhiYwDyAOoAbSJwZXEAAKBOIgAHSE9hY2RlZmhpbG9yc3UXARoBHwE6AVIBVQFiAWQBZgGCAakB6QHtAfIBYwB5ACdkUABZADuAqQCpQIABY3B5ACUBKAE1AfUhdGUGYWmg0iJ0KGFsRGlmZmVyZW50aWFsRAAAoEUhbCJleXMAAKAtIQACYWVpb0EBRAFKAU0B8iFvbgxhZABpAGwAO4DHAMdAcgBjAAhhbiJpbnQAAKAwIm8AdAAKYQABZG5ZAV0BaSJsbGEAuGB0I2VyRG90ALdg8gA5AWkAp2NyImNsZQAAAkRNUFRwAXQBeQF9AW8AdAAAoJkiaSJudXMAAKCWIuwhdXMAoJUiaSJtZXMAAKCXIm8AAAFjc4cBlAFrKndpc2VDb250b3VySW50ZWdyYWwAAKAyImUjQ3VybHkAAAFEUZwBpAFvJXVibGVRdW90ZQAAoB0gdSJvdGUAAKAZIAACbG5wdbABtgHNAdgBbwBuAGWgNyIAoHQqgAFnaXQAvAHBAcUB8iJ1ZW50AKBhIm4AdAAAoC8i7yV1ckludGVncmFsAKAuIgABZnLRAdMBAKACIe8iZHVjdACgECJuLnRlckNsb2Nrd2lzZUNvbnRvdXJJbnRlZ3JhbAAAoDMi7yFzcwCgLypjAHIAAOA12J7ccABDoNMiYQBwAACgTSKABURKU1phY2VmaW9zAAsCEgIVAhgCGwIsAjQCOQI9AnMCfwNvoEUh9CJyYWhkAKARKWMAeQACZGMAeQAFZGMAeQAPZIABZ3JzACECJQIoAuchZXIAoCEgcgAAoKEhaAB2AACg5CoAAWF5MAIzAvIhb24OYRRkbAB0oAciYQCUY3IAAOA12AfdAAFhZkECawIAAWNtRQJnAvIjaXRpY2FsAAJBREdUUAJUAl8CYwJjInV0ZQC0YG8AdAFZAloC2WJiJGxlQWN1dGUA3WJyImF2ZQBgYGkibGRlANxi7yFuZACgxCJmJWVyZW50aWFsRAAAoEYhcAR9AgAAAAAAAIECjgIAABoDZgAA4DXYO91EoagAhQKJAm8AdAAAoNwgcSJ1YWwAAKBQIuIhbGUAA0NETFJVVpkCqAK1Au8C/wIRA28AbgB0AG8AdQByAEkAbgB0AGUAZwByAGEA7ADEAW8AdAKvAgAAAACwAqhgbiNBcnJvdwAAoNMhAAFlb7kC0AJmAHQAgAFBUlQAwQLGAs0CciJyb3cAAKDQIekkZ2h0QXJyb3cAoNQhZQDlACsCbgBnAAABTFLWAugC5SFmdAABQVLcAuECciJyb3cAAKD4J+kkZ2h0QXJyb3cAoPon6SRnaHRBcnJvdwCg+SdpImdodAAAAUFU9gL7AnIicm93AACg0iFlAGUAAKCoInAAQQIGAwAAAAALA3Iicm93AACg0SFvJHduQXJyb3cAAKDVIWUlcnRpY2FsQmFyAACgJSJuAAADQUJMUlRhJAM2AzoDWgNxA3oDciJyb3cAAKGTIUJVLAMwA2EAcgAAoBMpcCNBcnJvdwAAoPUhciJldmUAEWPlIWZ00gJDAwAASwMAAFIDaSVnaHRWZWN0b3IAAKBQKWUkZVZlY3RvcgAAoF4p5SJjdG9yQqC9IWEAcgAAoFYpaSJnaHQA1AFiAwAAaQNlJGVWZWN0b3IAAKBfKeUiY3RvckKgwSFhAHIAAKBXKWUAZQBBoKQiciJyb3cAAKCnIXIAcgBvAPcAtAIAAWN0gwOHA3IA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YwAAoN8i4SFycnCgtiEAoD0pgKIqImJjZG9zACsVMBU6FT4VQRVyImNhcAAAoEgqAAFhdTQVNxVwAACgRipwAACgSipvAHQAAKCNInIAAKBFKgDgKiIA/gACYWxydksVURVuFXMVcgByAG2gtyEAoDwpeQCAAWV2dwBYFWUVaRVxAHACXxUAAAAAYxVyAGUA4wAXFXUA4wAZFWUAZQAAoM4iZSJkZ2UAAKDPImUAbgA7gKQApEBlI2Fycm93AAABbHJ7FX8V5SFmdACgtiFpImdodAAAoLchZQDkAG0VAAFjaYsVkRVvAG4AaQBuAPQAkwFuAHQAAKAxImwiY3R5AACgLSOACUFIYWJjZGVmaGlqbG9yc3R1d3oAuBW7Fb8V1RXgFegV+RUKFhUWHxZUFlcWZRbFFtsW7xb7FgUXChdyAPIAtAJhAHIAAKBlKQACZ2xyc8YVyhXOFdAV5yFlcgCgICDlIXRoAKA4IfIA9QxoAHagECAAoKMiawHZFd4VYSJyb3cAAKAPKWEA4wBfAgABYXnkFecV8iFvbg9hNGQAoUYhYW/tFfQVAAFnciEC8RVyAACgyiF0InNlcQAAoHcqgAFnbG0A/xUCFgUWO4CwALBAdABhALRjcCJ0eXYAAKCxKQABaXIOFhIW8yFodACgfykA4DXYId1hAHIAAAFschsWHRYAoMMhAKDCIYACYWVnc3YAKBauAjYWOhY+Fm0AAKHEIm9zLhY0Fm4AZABzoMQi9SFpdACgZiZhIm1tYQDdY2kAbgAAoPIiAKH3AGlvQxZRFmQAZQAAgfcAO29KFksW90BuI3RpbWVzAACgxyJuAPgAUBZjAHkAUmRjAG8CXhYAAAAAYhZyAG4AAKAeI28AcAAAoA0jgAJscHR1dwBuFnEWdRaSFp4W7CFhciRgZgAA4DXYVd0AotkCZW1wc30WhBaJFo0WcQBkoFAibwB0AACgUSJpIm51cwAAoDgi7CF1cwCgFCLxInVhcmUAoKEiYgBsAGUAYgBhAHIAdwBlAGQAZwDlANcAbgCAAWFkaAClFqoWtBZyAHIAbwD3APUMbwB3AG4AYQByAHIAbwB3APMA8xVhI3Jwb29uAAABbHK8FsAWZQBmAPQAHBZpAGcAaAD0AB4WYgHJFs8WawBhAHIAbwD3AJILbwLUFgAAAADYFnIAbgAAoB8jbwBwAACgDCOAAWNvdADhFukW7BYAAXJ55RboFgDgNdi53FVkbAAAoPYp8iFvaxFhAAFkcvMW9xZvAHQAAKDxImkA5qC/JVsSAAFhaP8WAhdyAPIANQNhAPIA1wvhIm5nbGUAoKYpAAFjaQ4XEBd5AF9k5yJyYXJyAKD/JwAJRGFjZGVmZ2xtbm9wcXJzdHV4MRc4F0YXWxcyBF4XaRd5F40XrBe0F78X2RcVGCEYLRg1GEAYAAFEbzUXgRZvAPQA+BUAAWNzPBdCF3UAdABlADuA6QDpQPQhZXIAoG4qAAJhaW95TRdQF1YXWhfyIW9uG2FyAGOgViI7gOoA6kDsIW9uAKBVIk1kbwB0ABdhAAFEcmIXZhdvAHQAAKBSIgDgNdgi3XKhmipuF3QXYQB2AGUAO4DoAOhAZKCWKm8AdAAAoJgqgKGZKmlscwCAF4UXhxfuInRlcnMAoOcjAKATIWSglSpvAHQAAKCXKoABYXBzAJMXlheiF2MAcgATYXQAeQBzogUinxcAAAAAoRdlAHQAAKAFInAAMaADIDMBqRerFwCgBCAAoAUgAAFnc7AXsRdLYXAAAKACIAABZ3C4F7sXbwBuABlhZgAA4DXYVt2AAWFscwDFF8sXzxdyAHOg1SJsAACg4yl1AHMAAKBxKmkAAKG1A2x21RfYF28AbgC1Y/VjAAJjc3V24BfoF/0XEBgAAWlv5BdWF3IAYwAAoFYiaQLuFwAAAADwF+0ADQThIW50AAFnbPUX+Rd0AHIAAKCWKuUhc3MAoJUqgAFhZWkAAxgGGAoYbABzAD1gcwB0AACgXyJ2AESgYSJEAACgeCrwImFyc2wAoOUpAAFEYRkYHRhvAHQAAKBTInIAcgAAoHEpgAFjZGkAJxgqGO0XcgAAoC8hbwD0AIwCAAFhaDEYMhi3YzuA8ADwQAABbXI5GD0YbAA7gOsA60BvAACgrCCAAWNpcABGGEgYSxhsACFgcwD0ACwEAAFlb08YVxhjAHQAYQB0AGkAbwDuABoEbgBlAG4AdABpAGEAbADlADME4Ql1GAAAgRgAAIMYiBgAAAAAoRilGAAAqhgAALsYvhjRGAAA1xgnGWwAbABpAG4AZwBkAG8AdABzAGUA8QBlF3kARGRtImFsZQAAoEAmgAFpbHIAjRiRGJ0Y7CFpZwCgA/tpApcYAAAAAJoYZwAAoAD7aQBnAACgBPsA4DXYI93sIWlnAKAB++whaWcA4GYAagCAAWFsdACvGLIYthh0AACgbSZpAGcAAKAC+24AcwAAoLElbwBmAJJh8AHCGAAAxhhmAADgNdhX3QABYWvJGMwYbADsAGsEdqDUIgCg2SphI3J0aW50AACgDSoAAWFv2hgiGQABY3PeGB8ZsQPnGP0YBRkSGRUZAAAdGbID7xjyGPQY9xj5GAAA+xg7gL0AvUAAoFMhO4C8ALxAAKBVIQCgWSEAoFshswEBGQAAAxkAoFQhAKBWIbQCCxkOGQAAAAAQGTuAvgC+QACgVyEAoFwhNQAAoFghtgEZGQAAGxkAoFohAKBdITgAAKBeIWwAAKBEIHcAbgAAoCIjYwByAADgNdi73IAIRWFiY2RlZmdpamxub3JzdHYARhlKGVoZXhlmGWkZkhmWGZkZnRmgGa0ZxhnLGc8Z4BkjGmygZyIAoIwqgAFjbXAAUBlTGVgZ9SF0ZfVhbQBhAOSgswM6FgCghipyImV2ZQAfYQABaXliGWUZcgBjAB1hM2RvAHQAIWGAoWUibHFzAMYEcBl6GfGhZSLOBAAAdhlsAGEAbgD0AN8EgKF+KmNkbACBGYQZjBljAACgqSpvAHQAb6CAKmyggioAoIQqZeDbIgD+cwAAoJQqcgAA4DXYJN3noGsirATtIWVsAKA3IWMAeQBTZIChdyJFYWoApxmpGasZAKCSKgCgpSoAoKQqAAJFYWVztBm2Gb0ZwhkAoGkicABwoIoq8iFveACgiipxoIgq8aCIKrUZaQBtAACg5yJwAGYAAOA12FjdYQB2AOUAYwIAAWNp0xnWGXIAAKAKIW0AAKFzImVs3BneGQCgjioAoJAqAIM+ADtjZGxxco0E6xn0GfgZ/BkBGgABY2nvGfEZAKCnKnIAAKB6Km8AdAAAoNci0CFhcgCglSl1ImVzdAAAoHwqgAJhZGVscwAKGvQZFhrVBCAa8AEPGgAAFBpwAHIAbwD4AFkZcgAAoHgpcQAAAWxxxAQbGmwAZQBzAPMASRlpAO0A5AQAAWVuJxouGnIjdG5lcXEAAOBpIgD+xQAsGgAFQWFiY2Vma29zeUAaQxpmGmoabRqDGocalhrCGtMacgDyAMwCAAJpbG1yShpOGlAaVBpyAHMA8ABxD2YAvWBpAGwA9AASBQABZHJYGlsaYwB5AEpkAKGUIWN3YBpkGmkAcgAAoEgpAKCtIWEAcgAAoA8h6SFyYyVhgAFhbHIAcxp7Gn8a8iF0c3WgZSZpAHQAAKBlJuwhaXAAoCYg4yFvbgCguSJyAADgNdgl3XMAAAFld4wakRphInJvdwAAoCUpYSJyb3cAAKAmKYACYW1vcHIAnxqjGqcauhq+GnIAcgAAoP8h9CFodACgOyJrAAABbHKsGrMaZSRmdGFycm93AACgqSHpJGdodGFycm93AKCqIWYAAOA12Fnd4iFhcgCgFSCAAWNsdADIGswa0BpyAADgNdi93GEAcwDoAGka8iFvaydhAAFicNca2xr1IWxsAKBDIOghZW4AoBAg4Qr2GgAA/RoAAAgbExsaGwAAIRs7GwAAAAA+G2IbmRuVG6sbAACyG80b0htjAHUAdABlADuA7QDtQAChYyBpeQEbBhtyAGMAO4DuAO5AOGQAAWN4CxsNG3kANWRjAGwAO4ChAKFAAAFmcssCFhsA4DXYJt1yAGEAdgBlADuA7ADsQIChSCFpbm8AJxsyGzYbAAFpbisbLxtuAHQAAKAMKnQAAKAtIuYhaW4AoNwpdABhAACgKSHsIWlnM2GAAWFvcABDG1sbXhuAAWNndABJG0sbWRtyACthgAFlbHAAcQVRG1UbaQBuAOUAyAVhAHIA9AByBWgAMWFmAACgtyJlAGQAtWEAoggiY2ZvdGkbbRt1G3kb4SFyZQCgBSFpAG4AdKAeImkAZQAAoN0pZABvAPQAWxsAoisiY2VscIEbhRuPG5QbYQBsAACguiIAAWdyiRuNG2UAcgDzACMQ4wCCG2EicmhrAACgFyryIW9kAKA8KgACY2dwdJ8boRukG6gbeQBRZG8AbgAvYWYAAOA12FrdYQC5Y3UAZQBzAHQAO4C/AL9AAAFjabUbuRtyAADgNdi+3G4AAKIIIkVkc3bCG8QbyBvQAwCg+SJvAHQAAKD1Inag9CIAoPMiaaBiIOwhZGUpYesB1hsAANkbYwB5AFZkbAA7gO8A70AAA2NmbW9zdeYb7hvyG/Ub+hsFHAABaXnqG+0bcgBjADVhOWRyAADgNdgn3eEhdGg3YnAAZgAA4DXYW93jAf8bAAADHHIAAOA12L/c8iFjeVhk6yFjeVRkAARhY2ZnaGpvcxUcGhwiHCYcKhwtHDAcNRzwIXBhdqC6A/BjAAFleR4cIRzkIWls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ZmdobG1vcHJzdHV3CiwNLBEsHSwnLDEsQCxLLFIsYix6LIQsjyzLLOgs7Sz/LAotcgDyAAkDYQByAACgYykAAWNyFSwbLHUAdABlADuA+gD6QPIACQ1yAOMBIywAACUseQBeZHYAZQBtYQABaXkrLDAscgBjADuA+wD7QENkgAFhYmgANyw6LD0scgDyANEO7CFhY3FhYQDyAOAOAAFpckQsSCzzIWh0AKB+KQDgNdgy3XIAYQB2AGUAO4D5APlAYQFWLF8scgAAAWxyWixcLACgvyEAoL4hbABrAACggCUAAWN0Zix2LG8CbCwAAAAAcyxyAG4AZaAcI3IAAKAcI28AcAAAoA8jcgBpAACg+CUAAWFsfiyBLGMAcgBrYTuAqACoQAABZ3CILIssbwBuAHNhZgAA4DXYZt0AA2FkaGxzdZksniynLLgsuyzFLHIAcgBvAPcACQ1vAHcAbgBhAHIAcgBvAPcA2A5hI3Jwb29uAAABbHKvLLMsZQBmAPQAWyxpAGcAaAD0AF0sdQDzAKYOaQAAocUDaGzBLMIs0mNvAG4AxWPwI2Fycm93cwCgyCGAAWNpdADRLOEs5CxvAtcsAAAAAN4scgBuAGWgHSNyAACgHSNvAHAAAKAOI24AZwBvYXIAaQAAoPklYwByAADgNdjK3IABZGlyAPMs9yz6LG8AdAAAoPAi7CFkZWlhaQBmoLUlAKC0JQABYW0DLQYtcgDyAMosbAA7gPwA/EDhIm5nbGUAoKcpgAdBQkRhY2RlZmxub3Byc3oAJy0qLTAtNC2bLZ0toS2/LcMtxy3TLdgt3C3gLfwtcgDyABADYQByAHag6CoAoOkqYQBzAOgA/gIAAW5yOC08LechcnQAoJwpgANla25wcnN0AJkpSC1NLVQtXi1iLYItYQBwAHAA4QAaHG8AdABoAGkAbgDnAKEXgAFoaXIAoSmzJFotbwBwAPQAdCVooJUh7wD4JgABaXVmLWotZwBtAOEAuygAAWJwbi14LXMjZXRuZXEAceCKIgD+AODLKgD+cyNldG5lcQBx4IsiAP4A4MwqAP4AAWhyhi2KLWUAdADhABIraSNhbmdsZQAAAWxyki2WLeUhZnQAoLIiaSJnaHQAAKCzInkAMmThIXNoAKCiIoABZWxyAKcttC24LWKiKCKuLQAAAACyLWEAcgAAoLsicQAAoFoi7CFpcACg7iIAAWJ0vC1eD2EA8gBfD3IAAOA12DPddAByAOkAlS1zAHUAAAFicM0t0C0A4IIi0iAA4IMi0iBwAGYAAOA12GfdcgBvAPAAWQt0AHIA6QCaLQABY3XkLegtcgAA4DXYy9wAAWJw7C30LW4AAAFFZXUt8S0A4IoiAP5uAAABRWV/LfktAOCLIgD+6SJnemFnAKCaKYADY2Vmb3BycwANLhAuJS4pLiMuLi40LukhcmN1YQABZGkULiEuAAFiZxguHC5hAHIAAKBfKmUAcaAnIgCgWSLlIXJwAKAYIXIAAOA12DTdcABmAADgNdho3WWgQCJhAHQA6ABqD2MAcgAA4DXYzNzjCuQRUC4AAFQuAABYLmIuAAAAAGMubS5wLnQuAAAAAIguki4AAJouJxIqEnQAcgDpAB0ScgAA4DXYNd0AAUFhWy5eLnIA8gDnAnIA8gCTB75jAAFBYWYuaS5yAPIA4AJyAPIAjAdhAPAAeh5pAHMAAKD7IoABZHB0APgReS6DLgABZmx9LoAuAOA12GnddQDzAP8RaQBtAOUABBIAAUFhiy6OLnIA8gDuAnIA8gCaBwABY3GVLgoScgAA4DXYzdwAAXB0nS6hLmwAdQDzACUScgDpACASAARhY2VmaW9zdbEuvC7ELsguzC7PLtQu2S5jAAABdXm2LrsudABlADuA/QD9QE9kAAFpecAuwy5yAGMAd2FLZG4AO4ClAKVAcgAA4DXYNt1jAHkAV2RwAGYAAOA12GrdYwByAADgNdjO3AABY23dLt8ueQBOZGwAO4D/AP9AAAVhY2RlZmhpb3N38y73Lv8uAi8MLxAvEy8YLx0vIi9jInV0ZQB6YQABYXn7Lv4u8iFvbn5hN2RvAHQAfGEAAWV0Bi8KL3QAcgDmAB8QYQC2Y3IAAOA12DfdYwB5ADZk5yJyYXJyAKDdIXAAZgAA4DXYa91jAHIAAOA12M/cAAFqbiYvKC8AoA0gagAAoAwg");
  const xmlDecodeTree = /* @__PURE__ */ decodeBase64("AAJhZ2xxBwARABMAFQBtAg0AAAAAAA8AcAAmYG8AcwAnYHQAPmB0ADxg9SFvdCJg");
  var BinTrieFlags;
  (function(BinTrieFlags2) {
    BinTrieFlags2[BinTrieFlags2["VALUE_LENGTH"] = 49152] = "VALUE_LENGTH";
    BinTrieFlags2[BinTrieFlags2["FLAG13"] = 8192] = "FLAG13";
    BinTrieFlags2[BinTrieFlags2["BRANCH_LENGTH"] = 8064] = "BRANCH_LENGTH";
    BinTrieFlags2[BinTrieFlags2["JUMP_TABLE"] = 127] = "JUMP_TABLE";
  })(BinTrieFlags || (BinTrieFlags = {}));
  var CharCodes$1;
  (function(CharCodes2) {
    CharCodes2[CharCodes2["NUM"] = 35] = "NUM";
    CharCodes2[CharCodes2["SEMI"] = 59] = "SEMI";
    CharCodes2[CharCodes2["EQUALS"] = 61] = "EQUALS";
    CharCodes2[CharCodes2["ZERO"] = 48] = "ZERO";
    CharCodes2[CharCodes2["NINE"] = 57] = "NINE";
    CharCodes2[CharCodes2["LOWER_A"] = 97] = "LOWER_A";
    CharCodes2[CharCodes2["LOWER_F"] = 102] = "LOWER_F";
    CharCodes2[CharCodes2["LOWER_X"] = 120] = "LOWER_X";
    CharCodes2[CharCodes2["LOWER_Z"] = 122] = "LOWER_Z";
    CharCodes2[CharCodes2["UPPER_A"] = 65] = "UPPER_A";
    CharCodes2[CharCodes2["UPPER_F"] = 70] = "UPPER_F";
    CharCodes2[CharCodes2["UPPER_Z"] = 90] = "UPPER_Z";
  })(CharCodes$1 || (CharCodes$1 = {}));
  const TO_LOWER_BIT = 32;
  function isNumber(code) {
    return code >= CharCodes$1.ZERO && code <= CharCodes$1.NINE;
  }
  function isHexadecimalCharacter(code) {
    return code >= CharCodes$1.UPPER_A && code <= CharCodes$1.UPPER_F || code >= CharCodes$1.LOWER_A && code <= CharCodes$1.LOWER_F;
  }
  function isAsciiAlphaNumeric(code) {
    return code >= CharCodes$1.UPPER_A && code <= CharCodes$1.UPPER_Z || code >= CharCodes$1.LOWER_A && code <= CharCodes$1.LOWER_Z || isNumber(code);
  }
  function isEntityInAttributeInvalidEnd(code) {
    return code === CharCodes$1.EQUALS || isAsciiAlphaNumeric(code);
  }
  var EntityDecoderState;
  (function(EntityDecoderState2) {
    EntityDecoderState2[EntityDecoderState2["EntityStart"] = 0] = "EntityStart";
    EntityDecoderState2[EntityDecoderState2["NumericStart"] = 1] = "NumericStart";
    EntityDecoderState2[EntityDecoderState2["NumericDecimal"] = 2] = "NumericDecimal";
    EntityDecoderState2[EntityDecoderState2["NumericHex"] = 3] = "NumericHex";
    EntityDecoderState2[EntityDecoderState2["NamedEntity"] = 4] = "NamedEntity";
  })(EntityDecoderState || (EntityDecoderState = {}));
  var DecodingMode;
  (function(DecodingMode2) {
    DecodingMode2[DecodingMode2["Legacy"] = 0] = "Legacy";
    DecodingMode2[DecodingMode2["Strict"] = 1] = "Strict";
    DecodingMode2[DecodingMode2["Attribute"] = 2] = "Attribute";
  })(DecodingMode || (DecodingMode = {}));
  class EntityDecoder {
    decodeTree;
    emitCodePoint;
    errors;
    constructor(decodeTree, emitCodePoint, errors) {
      this.decodeTree = decodeTree;
      this.emitCodePoint = emitCodePoint;
      this.errors = errors;
    }
    /** The current state of the decoder. */
    state = EntityDecoderState.EntityStart;
    /** Characters that were consumed while parsing an entity. */
    consumed = 1;
    /**
     * The result of the entity.
     *
     * Either the result index of a numeric entity, or the codepoint of a
     * numeric entity.
     */
    result = 0;
    /** The current index in the decode tree. */
    treeIndex = 0;
    /** The number of characters that were consumed in excess. */
    excess = 1;
    /** The mode in which the decoder is operating. */
    decodeMode = DecodingMode.Strict;
    /** The number of characters that have been consumed in the current run. */
    runConsumed = 0;
    /**
     * Resets the instance to make it reusable.
     * @param decodeMode Entity decoding mode to use.
     */
    startEntity(decodeMode) {
      this.decodeMode = decodeMode;
      this.state = EntityDecoderState.EntityStart;
      this.result = 0;
      this.treeIndex = 0;
      this.excess = 1;
      this.consumed = 1;
      this.runConsumed = 0;
    }
    /**
     * Write an entity to the decoder. This can be called multiple times with partial entities.
     * If the entity is incomplete, the decoder will return -1.
     *
     * Mirrors the implementation of `getDecoder`, but with the ability to stop decoding if the
     * entity is incomplete, and resume when the next string is written.
     * @param input The string containing the entity (or a continuation of the entity).
     * @param offset The offset at which the entity begins. Should be 0 if this is not the first call.
     * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
     */
    write(input2, offset) {
      switch (this.state) {
        case EntityDecoderState.EntityStart: {
          if (input2.charCodeAt(offset) === CharCodes$1.NUM) {
            this.state = EntityDecoderState.NumericStart;
            this.consumed += 1;
            return this.stateNumericStart(input2, offset + 1);
          }
          this.state = EntityDecoderState.NamedEntity;
          return this.stateNamedEntity(input2, offset);
        }
        case EntityDecoderState.NumericStart: {
          return this.stateNumericStart(input2, offset);
        }
        case EntityDecoderState.NumericDecimal: {
          return this.stateNumericDecimal(input2, offset);
        }
        case EntityDecoderState.NumericHex: {
          return this.stateNumericHex(input2, offset);
        }
        case EntityDecoderState.NamedEntity: {
          return this.stateNamedEntity(input2, offset);
        }
      }
    }
    /**
     * Switches between the numeric decimal and hexadecimal states.
     *
     * Equivalent to the `Numeric character reference state` in the HTML spec.
     * @param input The string containing the entity (or a continuation of the entity).
     * @param offset The current offset.
     * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
     */
    stateNumericStart(input2, offset) {
      if (offset >= input2.length) {
        return -1;
      }
      if ((input2.charCodeAt(offset) | TO_LOWER_BIT) === CharCodes$1.LOWER_X) {
        this.state = EntityDecoderState.NumericHex;
        this.consumed += 1;
        return this.stateNumericHex(input2, offset + 1);
      }
      this.state = EntityDecoderState.NumericDecimal;
      return this.stateNumericDecimal(input2, offset);
    }
    /**
     * Parses a hexadecimal numeric entity.
     *
     * Equivalent to the `Hexademical character reference state` in the HTML spec.
     * @param input The string containing the entity (or a continuation of the entity).
     * @param offset The current offset.
     * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
     */
    stateNumericHex(input2, offset) {
      while (offset < input2.length) {
        const char = input2.charCodeAt(offset);
        if (isNumber(char) || isHexadecimalCharacter(char)) {
          const digit = char <= CharCodes$1.NINE ? char - CharCodes$1.ZERO : (char | TO_LOWER_BIT) - CharCodes$1.LOWER_A + 10;
          this.result = this.result * 16 + digit;
          this.consumed++;
          offset++;
        } else {
          return this.emitNumericEntity(char, 3);
        }
      }
      return -1;
    }
    /**
     * Parses a decimal numeric entity.
     *
     * Equivalent to the `Decimal character reference state` in the HTML spec.
     * @param input The string containing the entity (or a continuation of the entity).
     * @param offset The current offset.
     * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
     */
    stateNumericDecimal(input2, offset) {
      while (offset < input2.length) {
        const char = input2.charCodeAt(offset);
        if (isNumber(char)) {
          this.result = this.result * 10 + (char - CharCodes$1.ZERO);
          this.consumed++;
          offset++;
        } else {
          return this.emitNumericEntity(char, 2);
        }
      }
      return -1;
    }
    /**
     * Validate and emit a numeric entity.
     *
     * Implements the logic from the `Hexademical character reference start
     * state` and `Numeric character reference end state` in the HTML spec.
     * @param lastCp The last code point of the entity. Used to see if the
     *               entity was terminated with a semicolon.
     * @param expectedLength The minimum number of characters that should be
     *                       consumed. Used to validate that at least one digit
     *                       was consumed.
     * @returns The number of characters that were consumed.
     */
    emitNumericEntity(lastCp, expectedLength) {
      if (this.consumed <= expectedLength) {
        this.errors?.absenceOfDigitsInNumericCharacterReference(this.consumed);
        return 0;
      }
      if (lastCp === CharCodes$1.SEMI) {
        this.consumed += 1;
      } else if (this.decodeMode === DecodingMode.Strict) {
        return 0;
      }
      this.emitCodePoint(replaceCodePoint(this.result), this.consumed);
      if (this.errors) {
        if (lastCp !== CharCodes$1.SEMI) {
          this.errors.missingSemicolonAfterCharacterReference();
        }
        this.errors.validateNumericCharacterReference(this.result);
      }
      return this.consumed;
    }
    /**
     * Parses a named entity.
     *
     * Equivalent to the `Named character reference state` in the HTML spec.
     * @param input The string containing the entity (or a continuation of the entity).
     * @param offset The current offset.
     * @returns The number of characters that were consumed, or -1 if the entity is incomplete.
     */
    stateNamedEntity(input2, offset) {
      const { decodeTree } = this;
      let current = decodeTree[this.treeIndex];
      let valueLength = (current & BinTrieFlags.VALUE_LENGTH) >> 14;
      while (offset < input2.length) {
        if (valueLength === 0 && (current & BinTrieFlags.FLAG13) !== 0) {
          const runLength = (current & BinTrieFlags.BRANCH_LENGTH) >> 7;
          if (this.runConsumed === 0) {
            const firstChar = current & BinTrieFlags.JUMP_TABLE;
            if (input2.charCodeAt(offset) !== firstChar) {
              return this.result === 0 ? 0 : this.emitNotTerminatedNamedEntity();
            }
            offset++;
            this.excess++;
            this.runConsumed++;
          }
          while (this.runConsumed < runLength) {
            if (offset >= input2.length) {
              return -1;
            }
            const charIndexInPacked = this.runConsumed - 1;
            const packedWord = decodeTree[this.treeIndex + 1 + (charIndexInPacked >> 1)];
            const expectedChar = charIndexInPacked % 2 === 0 ? packedWord & 255 : packedWord >> 8 & 255;
            if (input2.charCodeAt(offset) !== expectedChar) {
              this.runConsumed = 0;
              return this.result === 0 ? 0 : this.emitNotTerminatedNamedEntity();
            }
            offset++;
            this.excess++;
            this.runConsumed++;
          }
          this.runConsumed = 0;
          this.treeIndex += 1 + (runLength >> 1);
          current = decodeTree[this.treeIndex];
          valueLength = (current & BinTrieFlags.VALUE_LENGTH) >> 14;
        }
        if (offset >= input2.length)
          break;
        const char = input2.charCodeAt(offset);
        if (char === CharCodes$1.SEMI && valueLength !== 0 && (current & BinTrieFlags.FLAG13) !== 0) {
          return this.emitNamedEntityData(this.treeIndex, valueLength, this.consumed + this.excess);
        }
        this.treeIndex = determineBranch(decodeTree, current, this.treeIndex + Math.max(1, valueLength), char);
        if (this.treeIndex < 0) {
          return this.result === 0 || // If we are parsing an attribute
          this.decodeMode === DecodingMode.Attribute && // We shouldn't have consumed any characters after the entity,
          (valueLength === 0 || // And there should be no invalid characters.
          isEntityInAttributeInvalidEnd(char)) ? 0 : this.emitNotTerminatedNamedEntity();
        }
        current = decodeTree[this.treeIndex];
        valueLength = (current & BinTrieFlags.VALUE_LENGTH) >> 14;
        if (valueLength !== 0) {
          if (char === CharCodes$1.SEMI) {
            return this.emitNamedEntityData(this.treeIndex, valueLength, this.consumed + this.excess);
          }
          if (this.decodeMode !== DecodingMode.Strict && (current & BinTrieFlags.FLAG13) === 0) {
            this.result = this.treeIndex;
            this.consumed += this.excess;
            this.excess = 0;
          }
        }
        offset++;
        this.excess++;
      }
      return -1;
    }
    /**
     * Emit a named entity that was not terminated with a semicolon.
     * @returns The number of characters consumed.
     */
    emitNotTerminatedNamedEntity() {
      const { result, decodeTree } = this;
      const valueLength = (decodeTree[result] & BinTrieFlags.VALUE_LENGTH) >> 14;
      this.emitNamedEntityData(result, valueLength, this.consumed);
      this.errors?.missingSemicolonAfterCharacterReference();
      return this.consumed;
    }
    /**
     * Emit a named entity.
     * @param result The index of the entity in the decode tree.
     * @param valueLength The number of bytes in the entity.
     * @param consumed The number of characters consumed.
     * @returns The number of characters consumed.
     */
    emitNamedEntityData(result, valueLength, consumed) {
      const { decodeTree } = this;
      this.emitCodePoint(valueLength === 1 ? decodeTree[result] & ~(BinTrieFlags.VALUE_LENGTH | BinTrieFlags.FLAG13) : decodeTree[result + 1], consumed);
      if (valueLength === 3) {
        this.emitCodePoint(decodeTree[result + 2], consumed);
      }
      return consumed;
    }
    /**
     * Signal to the parser that the end of the input was reached.
     *
     * Remaining data will be emitted and relevant errors will be produced.
     * @returns The number of characters consumed.
     */
    end() {
      switch (this.state) {
        case EntityDecoderState.NamedEntity: {
          return this.result !== 0 && (this.decodeMode !== DecodingMode.Attribute || this.result === this.treeIndex) ? this.emitNotTerminatedNamedEntity() : 0;
        }
        // Otherwise, emit a numeric entity if we have one.
        case EntityDecoderState.NumericDecimal: {
          return this.emitNumericEntity(0, 2);
        }
        case EntityDecoderState.NumericHex: {
          return this.emitNumericEntity(0, 3);
        }
        case EntityDecoderState.NumericStart: {
          this.errors?.absenceOfDigitsInNumericCharacterReference(this.consumed);
          return 0;
        }
        case EntityDecoderState.EntityStart: {
          return 0;
        }
      }
    }
  }
  function determineBranch(decodeTree, current, nodeIndex, char) {
    const branchCount = (current & BinTrieFlags.BRANCH_LENGTH) >> 7;
    const jumpOffset = current & BinTrieFlags.JUMP_TABLE;
    if (branchCount === 0) {
      return jumpOffset !== 0 && char === jumpOffset ? nodeIndex : -1;
    }
    if (jumpOffset) {
      const value = char - jumpOffset;
      return value < 0 || value >= branchCount ? -1 : decodeTree[nodeIndex + value] - 1;
    }
    const packedKeySlots = branchCount + 1 >> 1;
    let lo = 0;
    let hi = branchCount - 1;
    while (lo <= hi) {
      const mid = lo + hi >>> 1;
      const slot = mid >> 1;
      const packed = decodeTree[nodeIndex + slot];
      const midKey = packed >> (mid & 1) * 8 & 255;
      if (midKey < char) {
        lo = mid + 1;
      } else if (midKey > char) {
        hi = mid - 1;
      } else {
        return decodeTree[nodeIndex + packedKeySlots + mid];
      }
    }
    return -1;
  }
  var CharCodes;
  (function(CharCodes2) {
    CharCodes2[CharCodes2["Tab"] = 9] = "Tab";
    CharCodes2[CharCodes2["NewLine"] = 10] = "NewLine";
    CharCodes2[CharCodes2["FormFeed"] = 12] = "FormFeed";
    CharCodes2[CharCodes2["CarriageReturn"] = 13] = "CarriageReturn";
    CharCodes2[CharCodes2["Space"] = 32] = "Space";
    CharCodes2[CharCodes2["ExclamationMark"] = 33] = "ExclamationMark";
    CharCodes2[CharCodes2["Number"] = 35] = "Number";
    CharCodes2[CharCodes2["Amp"] = 38] = "Amp";
    CharCodes2[CharCodes2["SingleQuote"] = 39] = "SingleQuote";
    CharCodes2[CharCodes2["DoubleQuote"] = 34] = "DoubleQuote";
    CharCodes2[CharCodes2["Dash"] = 45] = "Dash";
    CharCodes2[CharCodes2["Slash"] = 47] = "Slash";
    CharCodes2[CharCodes2["Zero"] = 48] = "Zero";
    CharCodes2[CharCodes2["Nine"] = 57] = "Nine";
    CharCodes2[CharCodes2["Semi"] = 59] = "Semi";
    CharCodes2[CharCodes2["Lt"] = 60] = "Lt";
    CharCodes2[CharCodes2["Eq"] = 61] = "Eq";
    CharCodes2[CharCodes2["Gt"] = 62] = "Gt";
    CharCodes2[CharCodes2["Questionmark"] = 63] = "Questionmark";
    CharCodes2[CharCodes2["UpperA"] = 65] = "UpperA";
    CharCodes2[CharCodes2["LowerA"] = 97] = "LowerA";
    CharCodes2[CharCodes2["UpperF"] = 70] = "UpperF";
    CharCodes2[CharCodes2["LowerF"] = 102] = "LowerF";
    CharCodes2[CharCodes2["UpperZ"] = 90] = "UpperZ";
    CharCodes2[CharCodes2["LowerZ"] = 122] = "LowerZ";
    CharCodes2[CharCodes2["LowerX"] = 120] = "LowerX";
    CharCodes2[CharCodes2["OpeningSquareBracket"] = 91] = "OpeningSquareBracket";
  })(CharCodes || (CharCodes = {}));
  var State;
  (function(State2) {
    State2[State2["Text"] = 1] = "Text";
    State2[State2["BeforeTagName"] = 2] = "BeforeTagName";
    State2[State2["InTagName"] = 3] = "InTagName";
    State2[State2["InSelfClosingTag"] = 4] = "InSelfClosingTag";
    State2[State2["BeforeClosingTagName"] = 5] = "BeforeClosingTagName";
    State2[State2["InClosingTagName"] = 6] = "InClosingTagName";
    State2[State2["AfterClosingTagName"] = 7] = "AfterClosingTagName";
    State2[State2["BeforeAttributeName"] = 8] = "BeforeAttributeName";
    State2[State2["InAttributeName"] = 9] = "InAttributeName";
    State2[State2["AfterAttributeName"] = 10] = "AfterAttributeName";
    State2[State2["BeforeAttributeValue"] = 11] = "BeforeAttributeValue";
    State2[State2["InAttributeValueDq"] = 12] = "InAttributeValueDq";
    State2[State2["InAttributeValueSq"] = 13] = "InAttributeValueSq";
    State2[State2["InAttributeValueNq"] = 14] = "InAttributeValueNq";
    State2[State2["BeforeDeclaration"] = 15] = "BeforeDeclaration";
    State2[State2["InDeclaration"] = 16] = "InDeclaration";
    State2[State2["InProcessingInstruction"] = 17] = "InProcessingInstruction";
    State2[State2["BeforeComment"] = 18] = "BeforeComment";
    State2[State2["CDATASequence"] = 19] = "CDATASequence";
    State2[State2["DeclarationSequence"] = 20] = "DeclarationSequence";
    State2[State2["InSpecialComment"] = 21] = "InSpecialComment";
    State2[State2["InCommentLike"] = 22] = "InCommentLike";
    State2[State2["SpecialStartSequence"] = 23] = "SpecialStartSequence";
    State2[State2["InSpecialTag"] = 24] = "InSpecialTag";
    State2[State2["InPlainText"] = 25] = "InPlainText";
    State2[State2["InEntity"] = 26] = "InEntity";
  })(State || (State = {}));
  function isWhitespace(c) {
    return c === CharCodes.Space || c === CharCodes.NewLine || c === CharCodes.Tab || c === CharCodes.FormFeed || c === CharCodes.CarriageReturn;
  }
  function isEndOfTagSection(c) {
    return c === CharCodes.Slash || c === CharCodes.Gt || isWhitespace(c);
  }
  function isASCIIAlpha(c) {
    return c >= CharCodes.LowerA && c <= CharCodes.LowerZ || c >= CharCodes.UpperA && c <= CharCodes.UpperZ;
  }
  var QuoteType;
  (function(QuoteType2) {
    QuoteType2[QuoteType2["NoValue"] = 0] = "NoValue";
    QuoteType2[QuoteType2["Unquoted"] = 1] = "Unquoted";
    QuoteType2[QuoteType2["Single"] = 2] = "Single";
    QuoteType2[QuoteType2["Double"] = 3] = "Double";
  })(QuoteType || (QuoteType = {}));
  const Sequences = {
    Empty: new Uint8Array(0),
    Cdata: new Uint8Array([67, 68, 65, 84, 65, 91]),
    // CDATA[
    CdataEnd: new Uint8Array([93, 93, 62]),
    // ]]>
    CommentEnd: new Uint8Array([45, 45, 33, 62]),
    // `--!>`
    Doctype: new Uint8Array([100, 111, 99, 116, 121, 112, 101]),
    // `doctype`
    IframeEnd: new Uint8Array([60, 47, 105, 102, 114, 97, 109, 101]),
    // `</iframe`
    NoembedEnd: new Uint8Array([
      60,
      47,
      110,
      111,
      101,
      109,
      98,
      101,
      100
    ]),
    // `</noembed`
    NoframesEnd: new Uint8Array([
      60,
      47,
      110,
      111,
      102,
      114,
      97,
      109,
      101,
      115
    ]),
    // `</noframes`
    Plaintext: new Uint8Array([
      60,
      47,
      112,
      108,
      97,
      105,
      110,
      116,
      101,
      120,
      116
    ]),
    // `</plaintext`
    ScriptEnd: new Uint8Array([60, 47, 115, 99, 114, 105, 112, 116]),
    // `<\/script`
    StyleEnd: new Uint8Array([60, 47, 115, 116, 121, 108, 101]),
    // `</style`
    TitleEnd: new Uint8Array([60, 47, 116, 105, 116, 108, 101]),
    // `</title`
    TextareaEnd: new Uint8Array([
      60,
      47,
      116,
      101,
      120,
      116,
      97,
      114,
      101,
      97
    ]),
    // `</textarea`
    XmpEnd: new Uint8Array([60, 47, 120, 109, 112])
    // `</xmp`
  };
  const specialStartSequences = /* @__PURE__ */ new Map([
    [Sequences.IframeEnd[2], Sequences.IframeEnd],
    [Sequences.NoembedEnd[2], Sequences.NoembedEnd],
    [Sequences.Plaintext[2], Sequences.Plaintext],
    [Sequences.ScriptEnd[2], Sequences.ScriptEnd],
    [Sequences.TitleEnd[2], Sequences.TitleEnd],
    [Sequences.XmpEnd[2], Sequences.XmpEnd]
  ]);
  class Tokenizer {
    cbs;
    /** The current state the tokenizer is in. */
    state = State.Text;
    /** The read buffer. */
    buffer = "";
    /** The beginning of the section that is currently being read. */
    sectionStart = 0;
    /** The index within the buffer that we are currently looking at. */
    index = 0;
    /** The start of the last entity. */
    entityStart = 0;
    /** Some behavior, eg. when decoding entities, is done while we are in another state. This keeps track of the other state type. */
    baseState = State.Text;
    /** For special parsing behavior inside of script and style tags. */
    isSpecial = false;
    /** Indicates whether the tokenizer has been paused. */
    running = true;
    /** The offset of the current buffer. */
    offset = 0;
    xmlMode;
    decodeEntities;
    recognizeSelfClosing;
    entityDecoder;
    constructor({ xmlMode = false, decodeEntities = true, recognizeSelfClosing = xmlMode }, cbs) {
      this.cbs = cbs;
      this.xmlMode = xmlMode;
      this.decodeEntities = decodeEntities;
      this.recognizeSelfClosing = recognizeSelfClosing;
      this.entityDecoder = new EntityDecoder(xmlMode ? xmlDecodeTree : htmlDecodeTree, (cp, consumed) => this.emitCodePoint(cp, consumed));
    }
    reset() {
      this.state = State.Text;
      this.buffer = "";
      this.sectionStart = 0;
      this.index = 0;
      this.baseState = State.Text;
      this.isSpecial = false;
      this.currentSequence = Sequences.Empty;
      this.sequenceIndex = 0;
      this.running = true;
      this.offset = 0;
    }
    write(chunk) {
      this.offset += this.buffer.length;
      this.buffer = chunk;
      this.parse();
    }
    end() {
      if (this.running)
        this.finish();
    }
    pause() {
      this.running = false;
    }
    resume() {
      this.running = true;
      if (this.index < this.buffer.length + this.offset) {
        this.parse();
      }
    }
    stateText(c) {
      if (c === CharCodes.Lt || !this.decodeEntities && this.fastForwardTo(CharCodes.Lt)) {
        if (this.index > this.sectionStart) {
          this.cbs.ontext(this.sectionStart, this.index);
        }
        this.state = State.BeforeTagName;
        this.sectionStart = this.index;
      } else if (this.decodeEntities && c === CharCodes.Amp) {
        this.startEntity();
      }
    }
    currentSequence = Sequences.Empty;
    sequenceIndex = 0;
    enterTagBody() {
      if (this.currentSequence === Sequences.Plaintext) {
        this.currentSequence = Sequences.Empty;
        this.state = State.InPlainText;
      } else if (this.isSpecial) {
        this.state = State.InSpecialTag;
        this.sequenceIndex = 0;
      } else {
        this.state = State.Text;
      }
    }
    /**
     * Match the opening tag name against an HTML text-only tag sequence.
     *
     * Some tags share an initial prefix (`script`/`style`, `title`/`textarea`,
     * `noembed`/`noframes`), so we may switch to an alternate sequence at the
     * first distinguishing byte.  On a successful full match we fall back to
     * the normal tag-name state; a later `>` will enter raw-text, RCDATA, or
     * plaintext mode based on `currentSequence` / `isSpecial`.
     * @param c Current character code point.
     */
    stateSpecialStartSequence(c) {
      const lower = c | 32;
      if (this.sequenceIndex < this.currentSequence.length) {
        if (lower === this.currentSequence[this.sequenceIndex]) {
          this.sequenceIndex++;
          return;
        }
        if (this.sequenceIndex === 3) {
          if (this.currentSequence === Sequences.ScriptEnd && lower === Sequences.StyleEnd[3]) {
            this.currentSequence = Sequences.StyleEnd;
            this.sequenceIndex = 4;
            return;
          }
          if (this.currentSequence === Sequences.TitleEnd && lower === Sequences.TextareaEnd[3]) {
            this.currentSequence = Sequences.TextareaEnd;
            this.sequenceIndex = 4;
            return;
          }
        } else if (this.sequenceIndex === 4 && this.currentSequence === Sequences.NoembedEnd && lower === Sequences.NoframesEnd[4]) {
          this.currentSequence = Sequences.NoframesEnd;
          this.sequenceIndex = 5;
          return;
        }
      } else if (isEndOfTagSection(c)) {
        this.sequenceIndex = 0;
        this.state = State.InTagName;
        this.stateInTagName(c);
        return;
      }
      this.isSpecial = false;
      this.currentSequence = Sequences.Empty;
      this.sequenceIndex = 0;
      this.state = State.InTagName;
      this.stateInTagName(c);
    }
    stateCDATASequence(c) {
      if (c === Sequences.Cdata[this.sequenceIndex]) {
        if (++this.sequenceIndex === Sequences.Cdata.length) {
          this.state = State.InCommentLike;
          this.currentSequence = Sequences.CdataEnd;
          this.sequenceIndex = 0;
          this.sectionStart = this.index + 1;
        }
      } else {
        this.sequenceIndex = 0;
        if (this.xmlMode) {
          this.state = State.InDeclaration;
          this.stateInDeclaration(c);
        } else {
          this.state = State.InSpecialComment;
          this.stateInSpecialComment(c);
        }
      }
    }
    /**
     * When we wait for one specific character, we can speed things up
     * by skipping through the buffer until we find it.
     * @param c Current character code point.
     * @returns Whether the character was found.
     */
    fastForwardTo(c) {
      while (++this.index < this.buffer.length + this.offset) {
        if (this.buffer.charCodeAt(this.index - this.offset) === c) {
          return true;
        }
      }
      this.index = this.buffer.length + this.offset - 1;
      return false;
    }
    /**
     * Emit a comment token and return to the text state.
     * @param offset Number of characters in the end sequence that have already been matched.
     */
    emitComment(offset) {
      this.cbs.oncomment(this.sectionStart, this.index, offset);
      this.sequenceIndex = 0;
      this.sectionStart = this.index + 1;
      this.state = State.Text;
    }
    /**
     * Comments and CDATA end with `-->` and `]]>`.
     *
     * Their common qualities are:
     * - Their end sequences have a distinct character they start with.
     * - That character is then repeated, so we have to check multiple repeats.
     * - All characters but the start character of the sequence can be skipped.
     * @param c Current character code point.
     */
    stateInCommentLike(c) {
      if (!this.xmlMode && this.currentSequence === Sequences.CommentEnd && this.sequenceIndex <= 1 && /*
       * We're still at the very start of the comment: the only
       * characters consumed since `<!--` are the dashes that
       * advanced sequenceIndex (0 for `<!-->`, 1 for `<!--->`).
       */
      this.index === this.sectionStart + this.sequenceIndex && c === CharCodes.Gt) {
        this.emitComment(this.sequenceIndex);
      } else if (this.currentSequence === Sequences.CommentEnd && this.sequenceIndex === 2 && c === CharCodes.Gt) {
        this.emitComment(2);
      } else if (this.currentSequence === Sequences.CommentEnd && this.sequenceIndex === this.currentSequence.length - 1 && c !== CharCodes.Gt) {
        this.sequenceIndex = Number(c === CharCodes.Dash);
      } else if (c === this.currentSequence[this.sequenceIndex]) {
        if (++this.sequenceIndex === this.currentSequence.length) {
          if (this.currentSequence === Sequences.CdataEnd) {
            this.cbs.oncdata(this.sectionStart, this.index, 2);
          } else {
            this.cbs.oncomment(this.sectionStart, this.index, 3);
          }
          this.sequenceIndex = 0;
          this.sectionStart = this.index + 1;
          this.state = State.Text;
        }
      } else if (this.sequenceIndex === 0) {
        if (this.fastForwardTo(this.currentSequence[0])) {
          this.sequenceIndex = 1;
        }
      } else if (c !== this.currentSequence[this.sequenceIndex - 1]) {
        this.sequenceIndex = 0;
      }
    }
    /**
     * HTML only allows ASCII alpha characters (a-z and A-Z) at the beginning of a tag name.
     *
     * XML allows a lot more characters here (@see https://www.w3.org/TR/REC-xml/#NT-NameStartChar).
     * We allow anything that wouldn't end the tag.
     * @param c Current character code point.
     */
    isTagStartChar(c) {
      return this.xmlMode ? !isEndOfTagSection(c) : isASCIIAlpha(c);
    }
    /**
     * Scan raw-text / RCDATA content for the matching end tag.
     *
     * For RCDATA tags (`<title>`, `<textarea>`) entities are decoded inline.
     * For raw-text tags (`<script>`, `<style>`, etc.) we fast-forward to `<`.
     * @param c Current character code point.
     */
    stateInSpecialTag(c) {
      if (this.sequenceIndex === this.currentSequence.length) {
        if (isEndOfTagSection(c)) {
          const endOfText = this.index - this.currentSequence.length;
          if (this.sectionStart < endOfText) {
            const actualIndex = this.index;
            this.index = endOfText;
            this.cbs.ontext(this.sectionStart, endOfText);
            this.index = actualIndex;
          }
          this.isSpecial = false;
          this.sectionStart = endOfText + 2;
          this.stateInClosingTagName(c);
          return;
        }
        this.sequenceIndex = 0;
      }
      if ((c | 32) === this.currentSequence[this.sequenceIndex]) {
        this.sequenceIndex += 1;
      } else if (this.sequenceIndex === 0) {
        if (this.currentSequence === Sequences.TitleEnd || this.currentSequence === Sequences.TextareaEnd) {
          if (this.decodeEntities && c === CharCodes.Amp) {
            this.startEntity();
          }
        } else if (this.fastForwardTo(CharCodes.Lt)) {
          this.sequenceIndex = 1;
        }
      } else {
        this.sequenceIndex = Number(c === CharCodes.Lt);
      }
    }
    stateBeforeTagName(c) {
      if (c === CharCodes.ExclamationMark) {
        this.state = State.BeforeDeclaration;
        this.sectionStart = this.index + 1;
      } else if (c === CharCodes.Questionmark) {
        if (this.xmlMode) {
          this.state = State.InProcessingInstruction;
          this.sequenceIndex = 0;
          this.sectionStart = this.index + 1;
        } else {
          this.state = State.InSpecialComment;
          this.sectionStart = this.index;
        }
      } else if (this.isTagStartChar(c)) {
        this.sectionStart = this.index;
        const special = this.xmlMode || this.cbs.isInForeignContext?.() ? void 0 : specialStartSequences.get(c | 32);
        if (special === void 0) {
          this.state = State.InTagName;
        } else {
          this.isSpecial = true;
          this.currentSequence = special;
          this.sequenceIndex = 3;
          this.state = State.SpecialStartSequence;
        }
      } else if (c === CharCodes.Slash) {
        this.state = State.BeforeClosingTagName;
      } else {
        this.state = State.Text;
        this.stateText(c);
      }
    }
    stateInTagName(c) {
      if (isEndOfTagSection(c)) {
        this.cbs.onopentagname(this.sectionStart, this.index);
        this.sectionStart = -1;
        this.state = State.BeforeAttributeName;
        this.stateBeforeAttributeName(c);
      }
    }
    stateBeforeClosingTagName(c) {
      if (isWhitespace(c)) {
        if (this.xmlMode) ;
        else {
          this.state = State.InSpecialComment;
          this.sectionStart = this.index;
        }
      } else if (c === CharCodes.Gt) {
        this.state = State.Text;
        if (!this.xmlMode) {
          this.sectionStart = this.index + 1;
        }
      } else {
        this.state = this.isTagStartChar(c) ? State.InClosingTagName : State.InSpecialComment;
        this.sectionStart = this.index;
      }
    }
    stateInClosingTagName(c) {
      if (isEndOfTagSection(c)) {
        this.cbs.onclosetag(this.sectionStart, this.index);
        this.sectionStart = -1;
        this.state = State.AfterClosingTagName;
        this.stateAfterClosingTagName(c);
      }
    }
    stateAfterClosingTagName(c) {
      if (c === CharCodes.Gt || this.fastForwardTo(CharCodes.Gt)) {
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      }
    }
    stateBeforeAttributeName(c) {
      if (c === CharCodes.Gt) {
        this.cbs.onopentagend(this.index);
        this.enterTagBody();
        this.sectionStart = this.index + 1;
      } else if (c === CharCodes.Slash) {
        this.state = State.InSelfClosingTag;
      } else if (!isWhitespace(c)) {
        this.state = State.InAttributeName;
        this.sectionStart = this.index;
      }
    }
    /**
     * Handle `/` before `>` in an opening tag.
     *
     * In HTML mode, text-only tags ignore the self-closing flag and still enter
     * their raw-text/RCDATA/plaintext state unless self-closing tags are being
     * recognized. In XML mode, or for ordinary tags, the tokenizer returns to
     * regular text parsing after emitting the self-closing callback.
     * @param c Current character code point.
     */
    stateInSelfClosingTag(c) {
      if (c === CharCodes.Gt) {
        this.cbs.onselfclosingtag(this.index);
        this.sectionStart = this.index + 1;
        if (!this.recognizeSelfClosing) {
          this.enterTagBody();
          return;
        }
        this.state = State.Text;
        this.isSpecial = false;
        this.currentSequence = Sequences.Empty;
      } else if (!isWhitespace(c)) {
        this.state = State.BeforeAttributeName;
        this.stateBeforeAttributeName(c);
      }
    }
    stateInAttributeName(c) {
      if (c === CharCodes.Eq || isEndOfTagSection(c)) {
        this.cbs.onattribname(this.sectionStart, this.index);
        this.sectionStart = this.index;
        this.state = State.AfterAttributeName;
        this.stateAfterAttributeName(c);
      }
    }
    stateAfterAttributeName(c) {
      if (c === CharCodes.Eq) {
        this.state = State.BeforeAttributeValue;
      } else if (c === CharCodes.Slash || c === CharCodes.Gt) {
        this.cbs.onattribend(QuoteType.NoValue, this.sectionStart);
        this.sectionStart = -1;
        this.state = State.BeforeAttributeName;
        this.stateBeforeAttributeName(c);
      } else if (!isWhitespace(c)) {
        this.cbs.onattribend(QuoteType.NoValue, this.sectionStart);
        this.state = State.InAttributeName;
        this.sectionStart = this.index;
      }
    }
    stateBeforeAttributeValue(c) {
      if (c === CharCodes.DoubleQuote) {
        this.state = State.InAttributeValueDq;
        this.sectionStart = this.index + 1;
      } else if (c === CharCodes.SingleQuote) {
        this.state = State.InAttributeValueSq;
        this.sectionStart = this.index + 1;
      } else if (!isWhitespace(c)) {
        this.sectionStart = this.index;
        this.state = State.InAttributeValueNq;
        this.stateInAttributeValueNoQuotes(c);
      }
    }
    handleInAttributeValue(c, quote) {
      if (c === quote || !this.decodeEntities && this.fastForwardTo(quote)) {
        this.cbs.onattribdata(this.sectionStart, this.index);
        this.sectionStart = -1;
        this.cbs.onattribend(quote === CharCodes.DoubleQuote ? QuoteType.Double : QuoteType.Single, this.index + 1);
        this.state = State.BeforeAttributeName;
      } else if (this.decodeEntities && c === CharCodes.Amp) {
        this.startEntity();
      }
    }
    stateInAttributeValueDoubleQuotes(c) {
      this.handleInAttributeValue(c, CharCodes.DoubleQuote);
    }
    stateInAttributeValueSingleQuotes(c) {
      this.handleInAttributeValue(c, CharCodes.SingleQuote);
    }
    stateInAttributeValueNoQuotes(c) {
      if (isWhitespace(c) || c === CharCodes.Gt) {
        this.cbs.onattribdata(this.sectionStart, this.index);
        this.sectionStart = -1;
        this.cbs.onattribend(QuoteType.Unquoted, this.index);
        this.state = State.BeforeAttributeName;
        this.stateBeforeAttributeName(c);
      } else if (this.decodeEntities && c === CharCodes.Amp) {
        this.startEntity();
      }
    }
    /**
     * Distinguish between CDATA, declarations, HTML comments, and HTML bogus
     * comments after `<!`.
     *
     * In HTML mode, only real comments and doctypes stay on declaration paths;
     * everything else becomes a bogus comment terminated by the next `>`.
     * @param c Current character code point.
     */
    stateBeforeDeclaration(c) {
      if (c === CharCodes.OpeningSquareBracket) {
        this.state = State.CDATASequence;
        this.sequenceIndex = 0;
      } else if (this.xmlMode) {
        this.state = c === CharCodes.Dash ? State.BeforeComment : State.InDeclaration;
      } else if ((c | 32) === Sequences.Doctype[0]) {
        this.state = State.DeclarationSequence;
        this.currentSequence = Sequences.Doctype;
        this.sequenceIndex = 1;
      } else if (c === CharCodes.Gt) {
        this.cbs.oncomment(this.sectionStart, this.index, 0);
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      } else if (c === CharCodes.Dash) {
        this.state = State.BeforeComment;
      } else {
        this.state = State.InSpecialComment;
      }
    }
    /**
     * Continue matching `doctype` after `<!d`.
     *
     * A full `doctype` match stays on the declaration path; any other name falls
     * back to an HTML bogus comment, which matches browser behavior for
     * non-doctype `<!...>` constructs.
     * @param c Current character code point.
     */
    stateDeclarationSequence(c) {
      if (this.sequenceIndex === this.currentSequence.length) {
        this.state = State.InDeclaration;
        this.stateInDeclaration(c);
      } else if ((c | 32) === this.currentSequence[this.sequenceIndex]) {
        this.sequenceIndex += 1;
      } else if (c === CharCodes.Gt) {
        this.cbs.oncomment(this.sectionStart, this.index, 0);
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      } else {
        this.state = State.InSpecialComment;
      }
    }
    stateInDeclaration(c) {
      if (c === CharCodes.Gt || this.fastForwardTo(CharCodes.Gt)) {
        this.cbs.ondeclaration(this.sectionStart, this.index);
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      }
    }
    /**
     * XML processing instructions (`<?...?>`).
     *
     * In HTML mode `<?` is routed to `InSpecialComment` instead, so this
     * state is only reachable in XML mode.
     * @param c Current character code point.
     */
    stateInProcessingInstruction(c) {
      if (c === CharCodes.Questionmark) {
        this.sequenceIndex = 1;
      } else if (c === CharCodes.Gt && this.sequenceIndex === 1) {
        this.cbs.onprocessinginstruction(this.sectionStart, this.index - 1);
        this.sequenceIndex = 0;
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      } else {
        this.sequenceIndex = Number(this.fastForwardTo(CharCodes.Questionmark));
      }
    }
    stateBeforeComment(c) {
      if (c === CharCodes.Dash) {
        this.state = State.InCommentLike;
        this.currentSequence = Sequences.CommentEnd;
        this.sequenceIndex = 0;
        this.sectionStart = this.index + 1;
      } else if (this.xmlMode) {
        this.state = State.InDeclaration;
      } else if (c === CharCodes.Gt) {
        this.cbs.oncomment(this.sectionStart, this.index, 0);
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      } else {
        this.state = State.InSpecialComment;
      }
    }
    stateInSpecialComment(c) {
      if (c === CharCodes.Gt || this.fastForwardTo(CharCodes.Gt)) {
        this.cbs.oncomment(this.sectionStart, this.index, 0);
        this.state = State.Text;
        this.sectionStart = this.index + 1;
      }
    }
    startEntity() {
      this.baseState = this.state;
      this.state = State.InEntity;
      this.entityStart = this.index;
      this.entityDecoder.startEntity(this.xmlMode ? DecodingMode.Strict : this.baseState === State.Text || this.baseState === State.InSpecialTag ? DecodingMode.Legacy : DecodingMode.Attribute);
    }
    stateInEntity() {
      const indexInBuffer = this.index - this.offset;
      const length = this.entityDecoder.write(this.buffer, indexInBuffer);
      if (length >= 0) {
        this.state = this.baseState;
        if (length === 0) {
          this.index -= 1;
        }
      } else {
        if (indexInBuffer < this.buffer.length && this.buffer.charCodeAt(indexInBuffer) === CharCodes.Amp) {
          this.state = this.baseState;
          this.index -= 1;
          return;
        }
        this.index = this.offset + this.buffer.length - 1;
      }
    }
    /**
     * Remove data that has already been consumed from the buffer.
     */
    cleanup() {
      if (this.running && this.sectionStart !== this.index) {
        if (this.state === State.Text || this.state === State.InPlainText || this.state === State.InSpecialTag && this.sequenceIndex === 0) {
          this.cbs.ontext(this.sectionStart, this.index);
          this.sectionStart = this.index;
        } else if (this.state === State.InAttributeValueDq || this.state === State.InAttributeValueSq || this.state === State.InAttributeValueNq) {
          this.cbs.onattribdata(this.sectionStart, this.index);
          this.sectionStart = this.index;
        }
      }
    }
    shouldContinue() {
      return this.index < this.buffer.length + this.offset && this.running;
    }
    /**
     * Iterates through the buffer, calling the function corresponding to the current state.
     *
     * States that are more likely to be hit are higher up, as a performance improvement.
     */
    parse() {
      while (this.shouldContinue()) {
        const c = this.buffer.charCodeAt(this.index - this.offset);
        switch (this.state) {
          case State.Text: {
            this.stateText(c);
            break;
          }
          case State.InPlainText: {
            this.index = this.buffer.length + this.offset - 1;
            break;
          }
          case State.SpecialStartSequence: {
            this.stateSpecialStartSequence(c);
            break;
          }
          case State.InSpecialTag: {
            this.stateInSpecialTag(c);
            break;
          }
          case State.CDATASequence: {
            this.stateCDATASequence(c);
            break;
          }
          case State.DeclarationSequence: {
            this.stateDeclarationSequence(c);
            break;
          }
          case State.InAttributeValueDq: {
            this.stateInAttributeValueDoubleQuotes(c);
            break;
          }
          case State.InAttributeName: {
            this.stateInAttributeName(c);
            break;
          }
          case State.InCommentLike: {
            this.stateInCommentLike(c);
            break;
          }
          case State.InSpecialComment: {
            this.stateInSpecialComment(c);
            break;
          }
          case State.BeforeAttributeName: {
            this.stateBeforeAttributeName(c);
            break;
          }
          case State.InTagName: {
            this.stateInTagName(c);
            break;
          }
          case State.InClosingTagName: {
            this.stateInClosingTagName(c);
            break;
          }
          case State.BeforeTagName: {
            this.stateBeforeTagName(c);
            break;
          }
          case State.AfterAttributeName: {
            this.stateAfterAttributeName(c);
            break;
          }
          case State.InAttributeValueSq: {
            this.stateInAttributeValueSingleQuotes(c);
            break;
          }
          case State.BeforeAttributeValue: {
            this.stateBeforeAttributeValue(c);
            break;
          }
          case State.BeforeClosingTagName: {
            this.stateBeforeClosingTagName(c);
            break;
          }
          case State.AfterClosingTagName: {
            this.stateAfterClosingTagName(c);
            break;
          }
          case State.InAttributeValueNq: {
            this.stateInAttributeValueNoQuotes(c);
            break;
          }
          case State.InSelfClosingTag: {
            this.stateInSelfClosingTag(c);
            break;
          }
          case State.InDeclaration: {
            this.stateInDeclaration(c);
            break;
          }
          case State.BeforeDeclaration: {
            this.stateBeforeDeclaration(c);
            break;
          }
          case State.BeforeComment: {
            this.stateBeforeComment(c);
            break;
          }
          case State.InProcessingInstruction: {
            this.stateInProcessingInstruction(c);
            break;
          }
          case State.InEntity: {
            this.stateInEntity();
            break;
          }
        }
        this.index++;
      }
      this.cleanup();
    }
    finish() {
      if (this.state === State.InEntity) {
        this.entityDecoder.end();
        this.state = this.baseState;
      }
      this.handleTrailingData();
      this.cbs.onend();
    }
    handleTrailingCommentLikeData(endIndex) {
      if (this.state !== State.InCommentLike) {
        return false;
      }
      if (this.currentSequence === Sequences.CdataEnd) {
        if (this.xmlMode) {
          if (this.sectionStart < endIndex) {
            this.cbs.oncdata(this.sectionStart, endIndex, 0);
          }
        } else {
          const cdataStart = this.sectionStart - Sequences.Cdata.length - 1;
          this.cbs.oncomment(cdataStart, endIndex, 0);
        }
      } else {
        const offset = this.xmlMode ? 0 : Math.min(this.sequenceIndex, Sequences.CommentEnd.length - 1);
        this.cbs.oncomment(this.sectionStart, endIndex, offset);
      }
      return true;
    }
    handleTrailingMarkupDeclaration(endIndex) {
      if (this.xmlMode) {
        switch (this.state) {
          case State.InSpecialComment:
          case State.BeforeComment:
          case State.CDATASequence:
          case State.DeclarationSequence:
          case State.InDeclaration: {
            this.cbs.ontext(this.sectionStart, endIndex);
            return true;
          }
          default: {
            return false;
          }
        }
      }
      switch (this.state) {
        case State.BeforeDeclaration:
        case State.InSpecialComment:
        case State.BeforeComment:
        case State.CDATASequence: {
          this.cbs.oncomment(this.sectionStart, endIndex, 0);
          return true;
        }
        case State.DeclarationSequence: {
          if (this.sequenceIndex !== Sequences.Doctype.length) {
            this.cbs.oncomment(this.sectionStart, endIndex, 0);
          }
          return true;
        }
        case State.InDeclaration: {
          return true;
        }
        default: {
          return false;
        }
      }
    }
    /** Handle any trailing data. */
    handleTrailingData() {
      const endIndex = this.buffer.length + this.offset;
      if (this.handleTrailingCommentLikeData(endIndex) || this.handleTrailingMarkupDeclaration(endIndex)) {
        return;
      }
      if (this.sectionStart >= endIndex) {
        return;
      }
      switch (this.state) {
        case State.InTagName:
        case State.BeforeAttributeName:
        case State.BeforeAttributeValue:
        case State.AfterAttributeName:
        case State.InAttributeName:
        case State.InAttributeValueSq:
        case State.InAttributeValueDq:
        case State.InAttributeValueNq:
        case State.InClosingTagName: {
          break;
        }
        default: {
          this.cbs.ontext(this.sectionStart, endIndex);
        }
      }
    }
    emitCodePoint(cp, consumed) {
      if (this.baseState !== State.Text && this.baseState !== State.InSpecialTag) {
        if (this.sectionStart < this.entityStart) {
          this.cbs.onattribdata(this.sectionStart, this.entityStart);
        }
        this.sectionStart = this.entityStart + consumed;
        this.index = this.sectionStart - 1;
        this.cbs.onattribentity(cp);
      } else {
        if (this.sectionStart < this.entityStart) {
          this.cbs.ontext(this.sectionStart, this.entityStart);
        }
        this.sectionStart = this.entityStart + consumed;
        this.index = this.sectionStart - 1;
        this.cbs.ontextentity(cp, this.sectionStart);
      }
    }
  }
  const { fromCodePoint } = String;
  const formTags = /* @__PURE__ */ new Set([
    "input",
    "option",
    "optgroup",
    "select",
    "button",
    "datalist",
    "textarea"
  ]);
  const pTag = /* @__PURE__ */ new Set(["p"]);
  const headingTags = /* @__PURE__ */ new Set(["h1", "h2", "h3", "h4", "h5", "h6", "p"]);
  const tableSectionTags = /* @__PURE__ */ new Set(["thead", "tbody"]);
  const ddtTags = /* @__PURE__ */ new Set(["dd", "dt"]);
  const rtpTags = /* @__PURE__ */ new Set(["rt", "rp"]);
  const openImpliesClose = /* @__PURE__ */ new Map([
    ["tr", /* @__PURE__ */ new Set(["tr", "th", "td"])],
    ["th", /* @__PURE__ */ new Set(["th"])],
    ["td", /* @__PURE__ */ new Set(["thead", "th", "td"])],
    ["body", /* @__PURE__ */ new Set(["head", "link", "script"])],
    ["a", /* @__PURE__ */ new Set(["a"])],
    ["li", /* @__PURE__ */ new Set(["li"])],
    ["p", pTag],
    ["h1", headingTags],
    ["h2", headingTags],
    ["h3", headingTags],
    ["h4", headingTags],
    ["h5", headingTags],
    ["h6", headingTags],
    ["select", formTags],
    ["input", formTags],
    ["output", formTags],
    ["button", formTags],
    ["datalist", formTags],
    ["textarea", formTags],
    ["option", /* @__PURE__ */ new Set(["option"])],
    ["optgroup", /* @__PURE__ */ new Set(["optgroup", "option"])],
    ["dd", ddtTags],
    ["dt", ddtTags],
    ["address", pTag],
    ["article", pTag],
    ["aside", pTag],
    ["blockquote", pTag],
    ["details", pTag],
    ["div", pTag],
    ["dl", pTag],
    ["fieldset", pTag],
    ["figcaption", pTag],
    ["figure", pTag],
    ["footer", pTag],
    ["form", pTag],
    ["header", pTag],
    ["hr", pTag],
    ["main", pTag],
    ["nav", pTag],
    ["ol", pTag],
    ["pre", pTag],
    ["section", pTag],
    ["table", pTag],
    ["ul", pTag],
    ["rt", rtpTags],
    ["rp", rtpTags],
    ["tbody", tableSectionTags],
    ["tfoot", tableSectionTags]
  ]);
  const DOCUMENT_TYPE = "doctype";
  const voidElements = /* @__PURE__ */ new Set([
    "area",
    "base",
    "basefont",
    "br",
    "col",
    "command",
    "embed",
    "frame",
    "hr",
    "img",
    "input",
    "isindex",
    "keygen",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr"
  ]);
  const foreignContextElements = /* @__PURE__ */ new Set(["math", "svg"]);
  const htmlIntegrationElements = /* @__PURE__ */ new Set([
    "mi",
    "mo",
    "mn",
    "ms",
    "mtext",
    "annotation-xml",
    "foreignObject",
    "desc",
    "title"
  ]);
  const svgTagNameAdjustments = /* @__PURE__ */ new Map([
    ["altglyph", "altGlyph"],
    ["altglyphdef", "altGlyphDef"],
    ["altglyphitem", "altGlyphItem"],
    ["animatecolor", "animateColor"],
    ["animatemotion", "animateMotion"],
    ["animatetransform", "animateTransform"],
    ["clippath", "clipPath"],
    ["feblend", "feBlend"],
    ["fecolormatrix", "feColorMatrix"],
    ["fecomponenttransfer", "feComponentTransfer"],
    ["fecomposite", "feComposite"],
    ["feconvolvematrix", "feConvolveMatrix"],
    ["fediffuselighting", "feDiffuseLighting"],
    ["fedisplacementmap", "feDisplacementMap"],
    ["fedistantlight", "feDistantLight"],
    ["fedropshadow", "feDropShadow"],
    ["feflood", "feFlood"],
    ["fefunca", "feFuncA"],
    ["fefuncb", "feFuncB"],
    ["fefuncg", "feFuncG"],
    ["fefuncr", "feFuncR"],
    ["fegaussianblur", "feGaussianBlur"],
    ["feimage", "feImage"],
    ["femerge", "feMerge"],
    ["femergenode", "feMergeNode"],
    ["femorphology", "feMorphology"],
    ["feoffset", "feOffset"],
    ["fepointlight", "fePointLight"],
    ["fespecularlighting", "feSpecularLighting"],
    ["fespotlight", "feSpotLight"],
    ["fetile", "feTile"],
    ["feturbulence", "feTurbulence"],
    ["foreignobject", "foreignObject"],
    ["glyphref", "glyphRef"],
    ["lineargradient", "linearGradient"],
    ["radialgradient", "radialGradient"],
    ["textpath", "textPath"]
  ]);
  var ForeignContext;
  (function(ForeignContext2) {
    ForeignContext2[ForeignContext2["None"] = 0] = "None";
    ForeignContext2[ForeignContext2["Svg"] = 1] = "Svg";
    ForeignContext2[ForeignContext2["MathML"] = 2] = "MathML";
  })(ForeignContext || (ForeignContext = {}));
  const reNameEnd = /\s|\//;
  class Parser {
    options;
    /** The start index of the last event. */
    startIndex = 0;
    /** The end index of the last event. */
    endIndex = 0;
    /**
     * Store the start index of the current open tag,
     * so we can update the start index for attributes.
     */
    openTagStart = 0;
    tagname = "";
    attribname = "";
    attribvalue = "";
    attribs = null;
    stack = [];
    foreignContext;
    cbs;
    lowerCaseTagNames;
    lowerCaseAttributeNames;
    recognizeSelfClosing;
    /** We are parsing HTML. Inverse of the `xmlMode` option. */
    htmlMode;
    tokenizer;
    buffers = [];
    bufferOffset = 0;
    /** The index of the last written buffer. Used when resuming after a `pause()`. */
    writeIndex = 0;
    /** Indicates whether the parser has finished running / `.end` has been called. */
    ended = false;
    constructor(cbs, options = {}) {
      this.options = options;
      this.cbs = cbs ?? {};
      this.htmlMode = !this.options.xmlMode;
      this.lowerCaseTagNames = options.lowerCaseTags ?? this.htmlMode;
      this.lowerCaseAttributeNames = options.lowerCaseAttributeNames ?? this.htmlMode;
      this.recognizeSelfClosing = options.recognizeSelfClosing ?? !this.htmlMode;
      this.tokenizer = new (options.Tokenizer ?? Tokenizer)(this.options, this);
      this.foreignContext = [ForeignContext.None];
      this.cbs.onparserinit?.(this);
    }
    // Tokenizer event handlers
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    ontext(start, endIndex) {
      const data = this.getSlice(start, endIndex);
      this.endIndex = endIndex - 1;
      this.cbs.ontext?.(data);
      this.startIndex = endIndex;
    }
    /**
     * @param cp Current Unicode code point.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    ontextentity(cp, endIndex) {
      this.endIndex = endIndex - 1;
      this.cbs.ontext?.(fromCodePoint(cp));
      this.startIndex = endIndex;
    }
    /** @internal */
    isInForeignContext() {
      return this.foreignContext[0] !== ForeignContext.None;
    }
    /**
     * Checks if the current tag is a void element. Override this if you want
     * to specify your own additional void elements.
     * @param name Name of the pseudo selector.
     */
    isVoidElement(name) {
      return this.htmlMode && voidElements.has(name);
    }
    /**
     * Read a tag name from the buffer.
     *
     * When `lowerCaseTagNames` is enabled (the default in HTML mode), the name
     * is lowercased and may be adjusted for SVG casing or the `image` → `img`
     * alias.
     * @param start Start index of the tag name in the buffer.
     * @param endIndex End index of the tag name in the buffer.
     */
    readTagName(start, endIndex) {
      const name = this.lowerCaseTagNames ? this.getSlice(start, endIndex).toLowerCase() : this.getSlice(start, endIndex);
      if (!(this.lowerCaseTagNames && this.htmlMode)) {
        return name;
      }
      if (this.foreignContext[0] === ForeignContext.Svg) {
        return svgTagNameAdjustments.get(name) ?? name;
      }
      if (this.foreignContext.length > 1) {
        const adjusted = svgTagNameAdjustments.get(name);
        if (adjusted !== void 0 && this.stack.includes(adjusted)) {
          return adjusted;
        }
      }
      if (!this.isInForeignContext()) {
        return name === "image" ? "img" : name;
      }
      return name;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onopentagname(start, endIndex) {
      this.endIndex = endIndex;
      this.emitOpenTag(this.readTagName(start, endIndex));
    }
    emitOpenTag(name) {
      this.openTagStart = this.startIndex;
      this.tagname = name;
      if (this.htmlMode && name === "form" && this.stack.includes("form")) {
        this.tagname = "";
        return;
      }
      const impliesClose = this.htmlMode && openImpliesClose.get(name);
      if (impliesClose) {
        while (this.stack.length > 0 && impliesClose.has(this.stack[0])) {
          this.popElement(true);
        }
      }
      if (!this.isVoidElement(name)) {
        this.stack.unshift(name);
        if (this.htmlMode) {
          if (name === "svg") {
            this.foreignContext.unshift(ForeignContext.Svg);
          } else if (name === "math") {
            this.foreignContext.unshift(ForeignContext.MathML);
          } else if (htmlIntegrationElements.has(name)) {
            this.foreignContext.unshift(ForeignContext.None);
          }
        }
      }
      this.cbs.onopentagname?.(name);
      if (this.cbs.onopentag)
        this.attribs = {};
    }
    endOpenTag(isImplied) {
      this.startIndex = this.openTagStart;
      if (this.attribs) {
        this.cbs.onopentag?.(this.tagname, this.attribs, isImplied);
        this.attribs = null;
      }
      if (this.cbs.onclosetag && this.isVoidElement(this.tagname)) {
        this.cbs.onclosetag(this.tagname, true);
      }
      this.tagname = "";
    }
    /**
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onopentagend(endIndex) {
      this.endIndex = endIndex;
      this.endOpenTag(false);
      this.startIndex = endIndex + 1;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onclosetag(start, endIndex) {
      this.endIndex = endIndex;
      const name = this.readTagName(start, endIndex);
      if (!this.isVoidElement(name)) {
        const pos = this.stack.indexOf(name);
        if (pos !== -1) {
          for (let index = 0; index < pos; index++) {
            this.popElement(true);
          }
          this.popElement(false);
        } else if (this.htmlMode && name === "p") {
          this.emitOpenTag("p");
          this.closeCurrentTag(true);
        }
      } else if (this.htmlMode && name === "br") {
        this.cbs.onopentagname?.("br");
        this.cbs.onopentag?.("br", {}, true);
        this.cbs.onclosetag?.("br", false);
      }
      this.startIndex = endIndex + 1;
    }
    /**
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onselfclosingtag(endIndex) {
      this.endIndex = endIndex;
      if (this.recognizeSelfClosing || this.isInForeignContext()) {
        this.closeCurrentTag(false);
        this.startIndex = endIndex + 1;
      } else {
        this.onopentagend(endIndex);
      }
    }
    /**
     * Pop the top element off the stack, emit a close event, and maintain
     * the foreign context stack.
     * @param implied Whether this close is implied (not from an explicit end tag).
     */
    popElement(implied) {
      const element = this.stack.shift();
      if (this.htmlMode && (foreignContextElements.has(element) || htmlIntegrationElements.has(element))) {
        this.foreignContext.shift();
      }
      this.cbs.onclosetag?.(element, implied);
    }
    closeCurrentTag(isOpenImplied) {
      const name = this.tagname;
      this.endOpenTag(isOpenImplied);
      if (this.stack[0] === name) {
        this.popElement(!isOpenImplied);
      }
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onattribname(start, endIndex) {
      this.startIndex = start;
      const name = this.getSlice(start, endIndex);
      this.attribname = this.lowerCaseAttributeNames ? name.toLowerCase() : name;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onattribdata(start, endIndex) {
      this.attribvalue += this.getSlice(start, endIndex);
    }
    /**
     * @param cp Current Unicode code point.
     * @internal
     */
    onattribentity(cp) {
      this.attribvalue += fromCodePoint(cp);
    }
    /**
     * @param quote Quote type used for the current attribute.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onattribend(quote, endIndex) {
      this.endIndex = endIndex;
      this.cbs.onattribute?.(this.attribname, this.attribvalue, quote === QuoteType.Double ? '"' : quote === QuoteType.Single ? "'" : quote === QuoteType.NoValue ? void 0 : null);
      if (this.attribs && !Object.hasOwn(this.attribs, this.attribname)) {
        this.attribs[this.attribname] = this.attribvalue;
      }
      this.attribvalue = "";
    }
    getInstructionName(value) {
      const index = value.search(reNameEnd);
      let name = index < 0 ? value : value.substr(0, index);
      if (this.lowerCaseTagNames) {
        name = name.toLowerCase();
      }
      return name;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    ondeclaration(start, endIndex) {
      this.endIndex = endIndex;
      const value = this.getSlice(start, endIndex);
      if (this.cbs.onprocessinginstruction) {
        const name = this.htmlMode ? this.lowerCaseTagNames ? DOCUMENT_TYPE : value.slice(0, DOCUMENT_TYPE.length) : this.getInstructionName(value);
        this.cbs.onprocessinginstruction(`!${name}`, `!${value}`);
      }
      this.startIndex = endIndex + 1;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @internal
     */
    onprocessinginstruction(start, endIndex) {
      this.endIndex = endIndex;
      const value = this.getSlice(start, endIndex);
      if (this.cbs.onprocessinginstruction) {
        const name = this.getInstructionName(value);
        this.cbs.onprocessinginstruction(`?${name}`, `?${value}`);
      }
      this.startIndex = endIndex + 1;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @param offset Offset applied when computing parser indices.
     * @internal
     */
    oncomment(start, endIndex, offset) {
      this.endIndex = endIndex;
      this.cbs.oncomment?.(this.getSlice(start, endIndex - offset));
      this.cbs.oncommentend?.();
      this.startIndex = endIndex + 1;
    }
    /**
     * @param start Start index for the current parser event.
     * @param endIndex End index for the current parser event.
     * @param offset Offset applied when computing parser indices.
     * @internal
     */
    oncdata(start, endIndex, offset) {
      this.endIndex = endIndex;
      const value = this.getSlice(start, endIndex - offset);
      if (!this.htmlMode || this.options.recognizeCDATA) {
        this.cbs.oncdatastart?.();
        this.cbs.ontext?.(value);
        this.cbs.oncdataend?.();
      } else if (this.isInForeignContext()) {
        this.cbs.ontext?.(value);
      } else {
        this.cbs.oncomment?.(`[CDATA[${value}]]`);
        this.cbs.oncommentend?.();
      }
      this.startIndex = endIndex + 1;
    }
    /** @internal */
    onend() {
      if (this.cbs.onclosetag) {
        this.endIndex = this.startIndex;
        for (let index = 0; index < this.stack.length; index++) {
          this.cbs.onclosetag(this.stack[index], true);
        }
      }
      this.cbs.onend?.();
    }
    /**
     * Resets the parser to a blank state, ready to parse a new HTML document
     */
    reset() {
      this.cbs.onreset?.();
      this.tokenizer.reset();
      this.tagname = "";
      this.attribname = "";
      this.attribvalue = "";
      this.attribs = null;
      this.stack.length = 0;
      this.startIndex = 0;
      this.endIndex = 0;
      this.cbs.onparserinit?.(this);
      this.buffers.length = 0;
      this.foreignContext.length = 0;
      this.foreignContext.unshift(ForeignContext.None);
      this.bufferOffset = 0;
      this.writeIndex = 0;
      this.ended = false;
    }
    /**
     * Resets the parser, then parses a complete document and
     * pushes it to the handler.
     * @param data Document to parse.
     */
    parseComplete(data) {
      this.reset();
      this.end(data);
    }
    getSlice(start, end) {
      if (start === end) {
        return "";
      }
      while (start - this.bufferOffset >= this.buffers[0].length) {
        this.shiftBuffer();
      }
      let slice = this.buffers[0].slice(start - this.bufferOffset, end - this.bufferOffset);
      while (end - this.bufferOffset > this.buffers[0].length) {
        this.shiftBuffer();
        slice += this.buffers[0].slice(0, end - this.bufferOffset);
      }
      return slice;
    }
    shiftBuffer() {
      this.bufferOffset += this.buffers[0].length;
      this.writeIndex--;
      this.buffers.shift();
    }
    /**
     * Parses a chunk of data and calls the corresponding callbacks.
     * @param chunk Chunk to parse.
     */
    write(chunk) {
      if (this.ended) {
        this.cbs.onerror?.(new Error(".write() after done!"));
        return;
      }
      this.buffers.push(chunk);
      if (this.tokenizer.running) {
        this.tokenizer.write(chunk);
        this.writeIndex++;
      }
    }
    /**
     * Parses the end of the buffer and clears the stack, calls onend.
     * @param chunk Optional final chunk to parse.
     */
    end(chunk) {
      if (this.ended) {
        this.cbs.onerror?.(new Error(".end() after done!"));
        return;
      }
      if (chunk)
        this.write(chunk);
      this.ended = true;
      this.tokenizer.end();
    }
    /**
     * Pauses parsing. The parser won't emit events until `resume` is called.
     */
    pause() {
      this.tokenizer.pause();
    }
    /**
     * Resumes parsing after `pause` was called.
     */
    resume() {
      this.tokenizer.resume();
      while (this.tokenizer.running && this.writeIndex < this.buffers.length) {
        this.tokenizer.write(this.buffers[this.writeIndex++]);
      }
      if (this.ended)
        this.tokenizer.end();
    }
  }
  var ElementType;
  (function(ElementType2) {
    ElementType2["Root"] = "root";
    ElementType2["Text"] = "text";
    ElementType2["Directive"] = "directive";
    ElementType2["Comment"] = "comment";
    ElementType2["Script"] = "script";
    ElementType2["Style"] = "style";
    ElementType2["Tag"] = "tag";
    ElementType2["CDATA"] = "cdata";
    ElementType2["Doctype"] = "doctype";
  })(ElementType || (ElementType = {}));
  function isTag$1(element) {
    return element.type === ElementType.Tag || element.type === ElementType.Script || element.type === ElementType.Style;
  }
  ElementType.Root;
  const Text$1 = ElementType.Text;
  ElementType.Directive;
  ElementType.Comment;
  const Script = ElementType.Script;
  const Style = ElementType.Style;
  const Tag = ElementType.Tag;
  ElementType.CDATA;
  ElementType.Doctype;
  class Node {
    /** Parent of the node */
    parent = null;
    /** Previous sibling */
    prev = null;
    /** Next sibling */
    next = null;
    /** The start index of the node. Requires `withStartIndices` on the handler to be `true. */
    startIndex = null;
    /** The end index of the node. Requires `withEndIndices` on the handler to be `true. */
    endIndex = null;
    // Read-write aliases for properties
    /**
     * Same as {@link parent}.
     * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
     */
    get parentNode() {
      return this.parent;
    }
    set parentNode(parent) {
      this.parent = parent;
    }
    /**
     * Same as {@link prev}.
     * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
     */
    get previousSibling() {
      return this.prev;
    }
    set previousSibling(previous) {
      this.prev = previous;
    }
    /**
     * Same as {@link next}.
     * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
     */
    get nextSibling() {
      return this.next;
    }
    set nextSibling(next2) {
      this.next = next2;
    }
    /**
     * Clone this node, and optionally its children.
     * @param recursive Clone child nodes as well.
     * @returns A clone of the node.
     */
    cloneNode(recursive = false) {
      return cloneNode(this, recursive);
    }
  }
  class DataNode extends Node {
    data;
    /**
     * @param data The content of the data node
     */
    constructor(data) {
      super();
      this.data = data;
    }
    /**
     * Same as {@link data}.
     * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
     */
    get nodeValue() {
      return this.data;
    }
    set nodeValue(data) {
      this.data = data;
    }
  }
  class Text extends DataNode {
    type = ElementType.Text;
    get nodeType() {
      return 3;
    }
  }
  class Comment extends DataNode {
    type = ElementType.Comment;
    get nodeType() {
      return 8;
    }
  }
  class ProcessingInstruction extends DataNode {
    type = ElementType.Directive;
    name;
    constructor(name, data) {
      super(data);
      this.name = name;
    }
    get nodeType() {
      return 1;
    }
    /** If this is a doctype, the document type name (parse5 only). */
    "x-name";
    /** If this is a doctype, the document type public identifier (parse5 only). */
    "x-publicId";
    /** If this is a doctype, the document type system identifier (parse5 only). */
    "x-systemId";
  }
  class NodeWithChildren extends Node {
    children;
    /**
     * @param children Children of the node. Only certain node types can have children.
     */
    constructor(children) {
      super();
      this.children = children;
    }
    // Aliases
    /** First child of the node. */
    get firstChild() {
      return this.children[0] ?? null;
    }
    /** Last child of the node. */
    get lastChild() {
      return this.children.length > 0 ? this.children[this.children.length - 1] : null;
    }
    /**
     * Same as {@link children}.
     * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
     */
    get childNodes() {
      return this.children;
    }
    set childNodes(children) {
      this.children = children;
    }
  }
  class CDATA extends NodeWithChildren {
    type = ElementType.CDATA;
    get nodeType() {
      return 4;
    }
  }
  class Document extends NodeWithChildren {
    type = ElementType.Root;
    get nodeType() {
      return 9;
    }
  }
  class Element extends NodeWithChildren {
    name;
    attribs;
    type;
    /**
     * @param name Name of the tag, eg. `div`, `span`.
     * @param attribs Object mapping attribute names to attribute values.
     * @param children Children of the node.
     * @param type Node type used for the new node instance.
     */
    constructor(name, attribs, children = [], type = name === "script" ? ElementType.Script : name === "style" ? ElementType.Style : ElementType.Tag) {
      super(children);
      this.name = name;
      this.attribs = attribs;
      this.type = type;
    }
    get nodeType() {
      return 1;
    }
    // DOM Level 1 aliases
    /**
     * Same as {@link name}.
     * [DOM spec](https://dom.spec.whatwg.org)-compatible alias.
     */
    get tagName() {
      return this.name;
    }
    set tagName(name) {
      this.name = name;
    }
    get attributes() {
      return Object.keys(this.attribs).map((name) => ({
        name,
        value: this.attribs[name],
        namespace: this["x-attribsNamespace"]?.[name],
        prefix: this["x-attribsPrefix"]?.[name]
      }));
    }
    /** Element namespace (parse5 only). */
    namespace;
    /** Element attribute namespaces (parse5 only). */
    "x-attribsNamespace";
    /** Element attribute namespace-related prefixes (parse5 only). */
    "x-attribsPrefix";
  }
  function isTag(node) {
    return isTag$1(node);
  }
  function isCDATA(node) {
    return node.type === ElementType.CDATA;
  }
  function isText(node) {
    return node.type === ElementType.Text;
  }
  function isComment(node) {
    return node.type === ElementType.Comment;
  }
  function isDirective(node) {
    return node.type === ElementType.Directive;
  }
  function isDocument(node) {
    return node.type === ElementType.Root;
  }
  function cloneNode(node, recursive = false) {
    let result;
    if (isText(node)) {
      result = new Text(node.data);
    } else if (isComment(node)) {
      result = new Comment(node.data);
    } else if (isTag(node)) {
      const children = recursive ? cloneChildren(node.children) : [];
      const clone2 = new Element(node.name, { ...node.attribs }, children);
      for (const child of children) {
        child.parent = clone2;
      }
      if (node.namespace != null) {
        clone2.namespace = node.namespace;
      }
      if (node["x-attribsNamespace"]) {
        clone2["x-attribsNamespace"] = { ...node["x-attribsNamespace"] };
      }
      if (node["x-attribsPrefix"]) {
        clone2["x-attribsPrefix"] = { ...node["x-attribsPrefix"] };
      }
      result = clone2;
    } else if (isCDATA(node)) {
      const children = recursive ? cloneChildren(node.children) : [];
      const clone2 = new CDATA(children);
      for (const child of children) {
        child.parent = clone2;
      }
      result = clone2;
    } else if (isDocument(node)) {
      const children = recursive ? cloneChildren(node.children) : [];
      const clone2 = new Document(children);
      for (const child of children) {
        child.parent = clone2;
      }
      if (node["x-mode"]) {
        clone2["x-mode"] = node["x-mode"];
      }
      result = clone2;
    } else if (isDirective(node)) {
      const instruction = new ProcessingInstruction(node.name, node.data);
      if (node["x-name"] != null) {
        instruction["x-name"] = node["x-name"];
        instruction["x-publicId"] = node["x-publicId"];
        instruction["x-systemId"] = node["x-systemId"];
      }
      result = instruction;
    } else {
      throw new Error(`Not implemented yet: ${node.type}`);
    }
    result.startIndex = node.startIndex;
    result.endIndex = node.endIndex;
    if (node.sourceCodeLocation != null) {
      result.sourceCodeLocation = node.sourceCodeLocation;
    }
    return result;
  }
  function cloneChildren(childs) {
    const children = childs.map((child) => cloneNode(child, true));
    for (let index = 1; index < children.length; index++) {
      children[index].prev = children[index - 1];
      children[index - 1].next = children[index];
    }
    return children;
  }
  const defaultOptions = {
    withStartIndices: false,
    withEndIndices: false,
    xmlMode: false
  };
  class DomHandler {
    /** The elements of the DOM */
    dom = [];
    /** The root element for the DOM */
    root = new Document(this.dom);
    /** Called once parsing has completed. */
    callback;
    /** Settings for the handler. */
    options;
    /** Callback whenever a tag is closed. */
    elementCB;
    /** Indicated whether parsing has been completed. */
    done = false;
    /** Stack of open tags. */
    tagStack = [this.root];
    /** A data node that is still being written to. */
    lastNode = null;
    /** Reference to the parser instance. Used for location information. */
    parser = null;
    /**
     * @param callback Called once parsing has completed.
     * @param options Settings for the handler.
     * @param elementCB Callback whenever a tag is closed.
     */
    constructor(callback, options, elementCB) {
      if (typeof options === "function") {
        elementCB = options;
        options = defaultOptions;
      }
      if (typeof callback === "object") {
        options = callback;
        callback = void 0;
      }
      this.callback = callback ?? null;
      this.options = options ?? defaultOptions;
      this.elementCB = elementCB ?? null;
    }
    onparserinit(parser) {
      this.parser = parser;
    }
    // Resets the handler back to starting state
    onreset() {
      this.dom = [];
      this.root = new Document(this.dom);
      this.done = false;
      this.tagStack = [this.root];
      this.lastNode = null;
      this.parser = null;
    }
    // Signals the handler that parsing is done
    onend() {
      if (this.done)
        return;
      this.done = true;
      this.parser = null;
      this.handleCallback(null);
    }
    onerror(error) {
      this.handleCallback(error);
    }
    onclosetag() {
      this.lastNode = null;
      const element = this.tagStack.pop();
      if (this.options.withEndIndices && this.parser) {
        element.endIndex = this.parser.endIndex;
      }
      if (this.elementCB)
        this.elementCB(element);
    }
    onopentag(name, attribs) {
      const type = this.options.xmlMode ? ElementType.Tag : void 0;
      const element = new Element(name, attribs, void 0, type);
      this.addNode(element);
      this.tagStack.push(element);
    }
    ontext(data) {
      const { lastNode } = this;
      if (lastNode && lastNode.type === ElementType.Text) {
        lastNode.data += data;
        if (this.options.withEndIndices && this.parser) {
          lastNode.endIndex = this.parser.endIndex;
        }
      } else {
        const node = new Text(data);
        this.addNode(node);
        this.lastNode = node;
      }
    }
    oncomment(data) {
      if (this.lastNode && this.lastNode.type === ElementType.Comment) {
        this.lastNode.data += data;
        return;
      }
      const node = new Comment(data);
      this.addNode(node);
      this.lastNode = node;
    }
    oncommentend() {
      this.lastNode = null;
    }
    oncdatastart() {
      const text = new Text("");
      const node = new CDATA([text]);
      this.addNode(node);
      text.parent = node;
      this.lastNode = text;
    }
    oncdataend() {
      this.lastNode = null;
    }
    onprocessinginstruction(name, data) {
      const node = new ProcessingInstruction(name, data);
      this.addNode(node);
    }
    handleCallback(error) {
      if (typeof this.callback === "function") {
        this.callback(error, this.dom);
      } else if (error) {
        throw error;
      }
    }
    addNode(node) {
      const parent = this.tagStack[this.tagStack.length - 1];
      const previousSibling = parent.children[parent.children.length - 1];
      if (this.options.withStartIndices && this.parser) {
        node.startIndex = this.parser.startIndex;
      }
      if (this.options.withEndIndices && this.parser) {
        node.endIndex = this.parser.endIndex;
      }
      parent.children.push(node);
      if (previousSibling) {
        node.prev = previousSibling;
        previousSibling.next = node;
      }
      node.parent = parent;
      this.lastNode = null;
    }
  }
  function parseDocument(data, options) {
    const handler = new DomHandler(void 0, options);
    new Parser(handler, options).end(data);
    return handler.root;
  }
  const NON_COPY = /* @__PURE__ */ new Set(["script", "style", "template"]);
  const ELEMENT_TYPES = /* @__PURE__ */ new Set([
    Tag,
    Script,
    Style
  ]);
  const PART_TAGS = /* @__PURE__ */ new Set([
    // paragraph
    "p",
    "pre",
    "blockquote",
    // list item
    "li",
    "dt",
    "dd",
    // table row
    "tr",
    // figure
    "figure",
    "img",
    "svg",
    "canvas",
    "picture",
    // question
    "fieldset",
    "label"
  ]);
  const QUESTION_ROLES = /* @__PURE__ */ new Set(["group", "radiogroup"]);
  const HOST_FRAGMENTS = ["data-facts", "data-followups"];
  const PICTURE_PREFIX = `${APP_FRAME_SCHEME}://${CARD_PICTURE_HOST}/`;
  const MEDIA_PREFIX = `${APP_FRAME_SCHEME}://${CARD_MEDIA_HOST}/`;
  function isPart(node, name) {
    if (PART_TAGS.has(name)) return true;
    const role = node.attribs?.role?.trim().toLowerCase();
    return role !== void 0 && QUESTION_ROLES.has(role);
  }
  function attributeValue(name, value) {
    if (name === "src" && value.startsWith(PICTURE_PREFIX)) {
      if (parseCardPictureFileName(value.slice(PICTURE_PREFIX.length))) return "picture";
    }
    if (hookAttributes("demo").includes(name) && value.startsWith(MEDIA_PREFIX)) {
      if (parseCardMediaFileName(value.slice(MEDIA_PREFIX.length))) return "recording";
    }
    return value.replace(/\s+/g, " ").trim();
  }
  function keyOf(node, media, includeScripts = false) {
    if (node.type === Text$1) return (node.data ?? "").replace(/\s+/g, " ").trim();
    if (!ELEMENT_TYPES.has(node.type)) return "";
    const name = node.name?.toLowerCase() ?? "";
    if (HOST_FRAGMENTS.some((attribute) => node.attribs?.[attribute] !== void 0)) return "";
    if (!includeScripts && NON_COPY.has(name)) return "";
    const attributes = Object.entries(node.attribs ?? {}).map(
      ([key, value]) => [key.toLowerCase(), attributeValue(key.toLowerCase(), value)]
    ).sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0).map(([key, value]) => `${key}="${value}"`).join(" ");
    const keys = (node.children ?? []).map((child) => keyOf(child, media, includeScripts)).filter(Boolean);
    if (includeScripts && !(node.children ?? []).some(
      (child) => child.type === Text$1 && (child.data ?? "").trim()
    ))
      keys.sort();
    const inner = keys.join(" ");
    return `<${name}${attributes ? ` ${attributes}` : ""}>${inner}</${name}>`;
  }
  function cardNavigationParts(body, media) {
    const document2 = parseDocument(body, { decodeEntities: true, withStartIndices: true });
    const result = [];
    const headings = [];
    const words = (node) => node.type === Text$1 ? node.data ?? "" : NON_COPY.has(node.name ?? "") ? "" : (node.children ?? []).map((child) => words(child)).join(" ");
    const walk = (nodes, ownerId) => {
      for (const node of nodes) {
        if (!ELEMENT_TYPES.has(node.type)) continue;
        const name = node.name?.toLowerCase() ?? "";
        if (NON_COPY.has(name) || HOST_FRAGMENTS.some((attribute) => node.attribs?.[attribute] !== void 0))
          continue;
        const start = node.startIndex;
        const level = /^h[1-6]$/.test(name) ? Number(name[1]) : 0;
        if (level && typeof start === "number") {
          const label = words(node).replace(/\s+/g, " ").trim();
          while (headings.length && headings[headings.length - 1].level >= level) headings.pop();
          const area = {
            start,
            label,
            path: JSON.stringify([...headings.map((h) => h.area.label), label]),
            ...node.attribs?.id || ownerId ? { stableId: node.attribs?.id || ownerId } : {}
          };
          headings.push({ level, area });
          result.push({ start, key: keyOf(node, media), heading: true, area });
        } else if (isPart(node, name) && typeof start === "number") {
          result.push({
            start,
            key: keyOf(node, media),
            heading: false,
            ...headings.at(-1) ? { area: headings.at(-1).area } : {}
          });
        } else walk(node.children ?? [], node.attribs?.id || ownerId);
      }
    };
    walk(document2.children);
    return result;
  }
  const revealsCss = `/* Shared by the shell and frame documents; no geometry or close choreography. */
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
`;
  const colorsCss = `/* Infinitary — color system. Dark ("deep space") is the default theme; light opts in via [data-theme="light"]. */
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
`;
  const effectsCss = '/* Infinitary — radii, shadows, glow, blur, motion. */\n:root {\n  --radius-xs: 3px; /* small controls: a 14-16px box that must read square, not round */\n  --radius-s: 6px; /* badges, keycaps */\n  --radius-m: 10px; /* buttons, inputs */\n  --radius-l: 16px; /* cards, panels */\n  --radius-pill: 999px; /* voice input shell, pills */\n  --shadow-1: 0 1px 2px rgba(0, 0, 0, 0.35);\n  --shadow-2: 0 8px 30px -12px rgba(0, 0, 0, 0.6);\n  --shadow-card: 0 12px 40px -16px rgba(0, 0, 0, 0.65), 0 1px 0 rgba(150, 180, 255, 0.06) inset;\n  --glow-accent: 0 0 32px -8px var(--accent-glow);\n  /* solid card material (legacy acrylic token names) */\n  --acrylic-bg: var(--bg-2);\n  --acrylic-blur: none; /* @kind other */\n  --acrylic-border: var(--line-1);\n  --acrylic-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.1), 0 24px 48px -24px rgba(0, 0, 0, 0.6);\n  --blur-overlay: blur(16px); /* @kind other */\n  /* motion — 160 in place, 360 for a surface, 700 for a dissolve; the card\n     stack, popovers, summaries and button labels have their own moves below */\n  --ease-drift: cubic-bezier(0.25, 0.1, 0.25, 1); /* @kind other */\n  --ease-out: cubic-bezier(0.32, 0.72, 0, 1); /* @kind other — the glide */\n  --dur-fast: 160ms; /* @kind other */\n  --dur-med: 360ms; /* @kind other */\n  --dur-slow: 700ms; /* @kind other */\n  --dur-fade: 160ms; /* @kind other — opacity-only opt-in, also under reduced motion */\n  --dur-quick: 200ms; /* @kind other — a popover grows, a summary slides or moves, a closed card drops away */\n  --dur-page: 300ms; /* @kind other — a card pages in, or comes forward after a close */\n  --dur-arrive: 420ms; /* @kind other — a card arrives on an empty stage */\n  --dur-popover-out: 120ms; /* @kind other */\n  --dur-summary-out: 100ms; /* @kind other */\n  --delay-label: 500ms; /* @kind other — the first icon-button label waits this long */\n  --move-page: 32px; /* @kind other — paging slides this far, with the arrow */\n  --move-arrive: 12px; /* @kind other */\n  --move-drop: 10px; /* @kind other — a closed card drops this far */\n  --move-stack: 8px; /* @kind other — the next card comes forward from this far up */\n  --move-summary: 8px; /* @kind other — a summary slides this far from what it describes */\n  --scale-arrive: 0.98; /* @kind other */\n  --scale-stack: 0.97; /* @kind other — a card behind the shown one */\n  --scale-pop: 0.94; /* @kind other — a popover grows from this size */\n}\n[data-theme="light"] {\n  --shadow-1: 0 1px 2px rgba(20, 30, 60, 0.1);\n  --shadow-2: 0 8px 30px -12px rgba(20, 30, 60, 0.18);\n  --shadow-card: 0 12px 40px -16px rgba(20, 30, 60, 0.22);\n  --acrylic-bg: var(--bg-2);\n  --acrylic-blur: none; /* @kind other */\n  --acrylic-border: var(--line-1);\n  --acrylic-shadow:\n    inset 0 1px 0 rgba(255, 255, 255, 0.9), 0 12px 32px -12px rgba(20, 30, 60, 0.28),\n    0 2px 8px -2px rgba(20, 30, 60, 0.1);\n}\n\n/* Shared by the shell and every frame. Character motion has its own guard.\n   Only short, explicitly opted-in opacity fades survive. */\n@media (prefers-reduced-motion: reduce) {\n  :root {\n    --dur-fast: 0ms;\n    --dur-med: 0ms;\n    --dur-slow: 0ms;\n    --dur-quick: 0ms;\n    --dur-page: 0ms;\n    --dur-arrive: 0ms;\n    --dur-popover-out: 0ms;\n    --dur-summary-out: 0ms;\n  }\n}\n';
  const fontsCss = '/* Infinitary webfonts - Space Grotesk (UI/display) + JetBrains Mono (data/code).\n   Vendored locally from Google Fonts (SIL Open Font License 1.1) so the package is offline-complete.\n   Binaries live in assets/fonts/; regenerate by re-fetching the css2 URL below with a woff2-capable UA.\n   https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@300..700&family=JetBrains+Mono:ital,wght@0,300..700;1,300..700&display=swap */\n/* JetBrains Mono italic cyrillic-ext */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: italic;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-italic-cyrillic-ext.woff2) format("woff2");\n  unicode-range: U+0460-052F, U+1C80-1C8A, U+20B4, U+2DE0-2DFF, U+A640-A69F, U+FE2E-FE2F;\n}\n/* JetBrains Mono italic cyrillic */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: italic;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-italic-cyrillic.woff2) format("woff2");\n  unicode-range: U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116;\n}\n/* JetBrains Mono italic greek */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: italic;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-italic-greek.woff2) format("woff2");\n  unicode-range: U+0370-0377, U+037A-037F, U+0384-038A, U+038C, U+038E-03A1, U+03A3-03FF;\n}\n/* JetBrains Mono italic vietnamese */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: italic;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-italic-vietnamese.woff2) format("woff2");\n  unicode-range:\n    U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;\n}\n/* JetBrains Mono italic latin-ext */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: italic;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-italic-latin-ext.woff2) format("woff2");\n  unicode-range:\n    U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;\n}\n/* JetBrains Mono italic latin */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: italic;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-italic-latin.woff2) format("woff2");\n  unicode-range:\n    U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;\n}\n/* JetBrains Mono normal cyrillic-ext */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-normal-cyrillic-ext.woff2) format("woff2");\n  unicode-range: U+0460-052F, U+1C80-1C8A, U+20B4, U+2DE0-2DFF, U+A640-A69F, U+FE2E-FE2F;\n}\n/* JetBrains Mono normal cyrillic */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-normal-cyrillic.woff2) format("woff2");\n  unicode-range: U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116;\n}\n/* JetBrains Mono normal greek */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-normal-greek.woff2) format("woff2");\n  unicode-range: U+0370-0377, U+037A-037F, U+0384-038A, U+038C, U+038E-03A1, U+03A3-03FF;\n}\n/* JetBrains Mono normal vietnamese */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-normal-vietnamese.woff2) format("woff2");\n  unicode-range:\n    U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;\n}\n/* JetBrains Mono normal latin-ext */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-normal-latin-ext.woff2) format("woff2");\n  unicode-range:\n    U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;\n}\n/* JetBrains Mono normal latin */\n@font-face {\n  font-family: "JetBrains Mono";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/jetbrainsmono-normal-latin.woff2) format("woff2");\n  unicode-range:\n    U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;\n}\n/* Space Grotesk normal vietnamese */\n@font-face {\n  font-family: "Space Grotesk";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/spacegrotesk-vietnamese.woff2) format("woff2");\n  unicode-range:\n    U+0102-0103, U+0110-0111, U+0128-0129, U+0168-0169, U+01A0-01A1, U+01AF-01B0, U+0300-0301, U+0303-0304, U+0308-0309, U+0323, U+0329, U+1EA0-1EF9, U+20AB;\n}\n/* Space Grotesk normal latin-ext */\n@font-face {\n  font-family: "Space Grotesk";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/spacegrotesk-latin-ext.woff2) format("woff2");\n  unicode-range:\n    U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF;\n}\n/* Space Grotesk normal latin */\n@font-face {\n  font-family: "Space Grotesk";\n  font-style: normal;\n  font-weight: 300 700;\n  font-display: swap;\n  src: url(../assets/fonts/spacegrotesk-latin.woff2) format("woff2");\n  unicode-range:\n    U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD;\n}\n';
  const spacingCss = "/* Infinitary — spacing scale (4px base). Generous whitespace is the default; density is the exception. */\n:root {\n  --space-1: 4px;\n  --space-2: 8px;\n  --space-3: 12px;\n  --space-4: 16px;\n  --space-5: 24px;\n  --space-6: 32px;\n  --space-7: 48px;\n  --space-8: 64px;\n  --space-9: 96px;\n  /* layout - dock rails are at least one fifth of the window, not resizable */\n  --rail-width: max(300px, 20vw);\n  /* layout - the voice input: one line is the pill, and the radius stays half of it at every height */\n  --prompt-height: calc(var(--space-7) + var(--space-1));\n  --prompt-radius: calc(var(--prompt-height) / 2);\n  /* layout - a card's reply field: one line of --text-sm is the pill (2px is its hairline), and the radius stays half of it at every height */\n  --reply-height: calc(var(--text-sm) * var(--leading-body) + 2 * var(--space-2) + 2px);\n  --reply-radius: calc(var(--reply-height) / 2);\n}\n";
  const typographyCss = '/* Infinitary — typography. Space Grotesk for UI and display, JetBrains Mono for data, keybinds, code. */\n:root {\n  --font-ui: "Space Grotesk", system-ui, sans-serif;\n  --font-mono: "JetBrains Mono", ui-monospace, monospace;\n  --text-xs: 11px; /* micro labels, uppercase tracked */\n  --text-sm: 12.5px; /* secondary, metadata */\n  --text-base: 14px; /* body */\n  --text-md: 16px; /* card titles, input text */\n  --text-lg: 20px; /* section titles */\n  --text-xl: 28px; /* card headlines */\n  --text-display: 44px; /* null-state greeting */\n  --leading-tight: 1.15;\n  --leading-body: 1.55;\n  --tracking-label: 0.09em; /* uppercase micro labels */\n  --tracking-display: -0.02em;\n  --weight-light: 300;\n  --weight-regular: 400;\n  --weight-medium: 500;\n  --weight-semibold: 600;\n}\nbody {\n  font-family: var(--font-ui);\n  font-size: var(--text-base);\n  line-height: var(--leading-body);\n  color: var(--text-body);\n  background: var(--bg-0);\n  -webkit-font-smoothing: antialiased;\n}\na {\n  color: var(--accent);\n  text-decoration: none;\n}\na:hover {\n  color: var(--accent-strong);\n}\n';
  const FONT_URL = /url\(\s*['"]?\.\.\/assets\/fonts\/([A-Za-z0-9._-]+)['"]?\s*\)/g;
  function frameFontFaces(css = fontsCss) {
    return css.replaceAll(FONT_URL, (_match, file) => `url(${frameFontUrl(file)})`);
  }
  const FRAME_BASE_STYLE = `
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
  /* A diagram the bridge tagged opens in the picture viewer on a click, as a picture does (INF-3107). */
  svg[data-inf-picture] { cursor: zoom-in; }
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
  /* The queue's own words on a sent-back change wrap whole, so its pause issue link stays in view (INF-3208). */
  .inf-fact[data-fact="batch"] .inf-fact-v { white-space: normal; overflow-wrap: anywhere; }
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
`;
  let cached;
  function frameStylesheet() {
    cached ??= [
      colorsCss,
      typographyCss,
      spacingCss,
      effectsCss,
      revealsCss,
      frameFontFaces(),
      FRAME_BASE_STYLE
    ].join("\n");
    return cached;
  }
  function cardBodyHtml(body) {
    return /<[a-z][\s\S]*>/i.test(body) ? body : plainTextBody(body);
  }
  function escapeHtml(text) {
    return text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#39;");
  }
  function plainTextBody(text) {
    const linked2 = splitCardBodyUrls(text).map((part) => {
      const escaped = escapeHtml(part.value);
      return part.type === "url" && isSafeCardHref(part.value) ? `<a href="${escaped}">${escaped}</a>` : escaped;
    }).join("");
    return linked2.split(/\n{2,}/).map((paragraph) => `<p>${paragraph.replaceAll("\n", "<br>")}</p>`).join("");
  }
  const CHANGE_GUTTER_PX = 8;
  function cardBodyMarkup(body, marks = []) {
    const html = cardBodyHtml(body);
    if (html !== body) return { html, marked: false };
    const parts = cardNavigationParts(body);
    const targets = parts.length <= REVISION_TARGETS_MAX ? parts.map((p) => p.start) : [];
    const starts = [.../* @__PURE__ */ new Set([...marks, ...targets])].sort((a, b) => b - a);
    let marked = html;
    const bars = [];
    for (const start of starts) {
      const tag = /^<[a-z][^\s/>]*/i.exec(marked.slice(start, start + 64));
      if (!tag) continue;
      const at = start + tag[0].length;
      const n = bars.length;
      const changed = marks.includes(start);
      marked = `${marked.slice(0, at)}${targets.includes(start) ? ` data-inf-target="${start}"` : ""}${changed ? ` data-inf-changed="${n}"` : ""}${marked.slice(at)}`;
      if (changed) bars.push(n);
    }
    if (bars.length === 0) return { html: marked, marked: false };
    const anchors = bars.map((n) => `[data-inf-changed="${n}"]{anchor-name:--fm-new-${n}}`).join("");
    const drawn = bars.map((n) => `<i data-inf-bar="" style="position-anchor:--fm-new-${n}"></i>`).join("");
    return {
      html: `${marked}<style>${anchors}</style><div data-inf-bars="" aria-hidden="true">${drawn}</div>`,
      marked: true
    };
  }
  const CARD_MEASURE_STYLE = `
  /* HtmlCardBody owns the vertical inset outside this auto-sized viewport.
     flow-root keeps child margins in the measured body without padding. */
  body { padding-block: 0; display: flow-root; }
  :is(p, ul, ol, dl, blockquote, h1, h2, h3, h4, h5, h6, figcaption, summary) { max-width: 66ch; }
  /* A group's caption is its own line under the strip (flex-basis 100%): a
     narrower box would let it rise beside the thumbnails, so the line keeps
     the group's width and its text keeps the measure. */
  .inf-pictures > figcaption { max-width: none; padding-right: max(0px, calc(100% - 66ch)); }
`;
  const CARD_CHANGES_STYLE = `
  body:has([data-inf-bars]) { padding-left: calc(var(--space-1) + ${CHANGE_GUTTER_PX}px); }
  [data-inf-bar] {
    position: absolute; left: calc(var(--space-1) - 2px); width: 2px;
    top: anchor(top); bottom: anchor(bottom);
    position-visibility: anchors-visible;
    border-radius: var(--radius-pill); background: var(--accent); pointer-events: none;
  }
`;
  const CARD_INSET_STYLE = `
  [data-inf-inset] {
    float: right; clear: right; margin: 0;
    width: max(0px, calc(var(--inf-inset-width, 0px) - var(--space-1)));
    height: var(--inf-inset-height, 0px);
  }
  [data-inf-inset] ~ .inf-panel { display: flow-root; }
  [data-inf-inset] ~ :nth-child(n + 3 of :is(h1, h2, h3, h4, h5, h6, :has(:is(h1, h2, h3, h4, h5, h6)))) {
    clear: right;
  }
`;
  const AFTER_MERGE_STYLE = `
  [data-inf-after-merge] { margin: 0 0 var(--space-3); padding: var(--space-2) var(--space-3); color: var(--fg-2); }
  [data-inf-after-merge] p { margin: 0; }
  [data-inf-after-merge] section + section { margin-top: var(--space-2); }
  [data-inf-after-merge-lead] { color: var(--fg-1); }
  [data-inf-after-merge-lead="captain"] { color: var(--warn); }
  [data-inf-after-merge] ul { margin: var(--space-1) 0 0; padding-left: var(--space-4); }
  [data-inf-after-merge] li + li { margin-top: var(--space-2); }
  [data-inf-after-merge] li > span { color: var(--fg-1); }
`;
  let cardStyle;
  function cardStylesheet() {
    cardStyle ??= `${frameStylesheet()}
${CARD_MEASURE_STYLE}
${CARD_CHANGES_STYLE}
${CARD_INSET_STYLE}
${AFTER_MERGE_STYLE}
${REVISION_HIGHLIGHT_STYLE}`;
    return cardStyle;
  }
  const REVISION_HIGHLIGHT_STYLE = `
  [data-inf-revision-highlight] { background-color: var(--accent-dim); box-shadow: var(--focus-ring-inset); }
`;
  const native = (message) => window.webkit.messageHandlers.cardHost.postMessage(message);
  let frame;
  let documentID;
  let input;
  let linked = [];
  const pressed = () => document.hasFocus() && navigator.userActivation.isActive;
  let next = 0;
  const collections = /* @__PURE__ */ new Map();
  const send = (message) => frame?.contentWindow?.postMessage({ fm: 2, ...message }, "*");
  const fail = (message) => new Error(message);
  window.addEventListener("message", (event) => {
    if (!frame || event.source !== frame.contentWindow) return;
    const parsed = frameMessageSchema.safeParse(event.data);
    if (!parsed.success) return;
    const message = parsed.data;
    if (message.type === "ready") {
      if (documentID || !message.document) return;
      documentID = message.document;
      void native({ type: "ready" }).catch(() => {
      });
      send({ type: "form", fill: cardAnswersSchema.parse(input.fill ?? []), readOnly: input.readOnly });
      send({ type: "keys", pictures: true, escape: false });
      send({ type: "width", width: input.width });
      if (linked.length > 0) send({ type: "tasks", keys: linked });
      send({ type: "initialize", document: documentID, latePictures: true });
      return;
    }
    if (!documentID || "document" in message && message.document && message.document !== documentID) return;
    switch (message.type) {
      case "answers": {
        const { questions: raw, ...reading } = message;
        const questions = cardQuestionsSchema.safeParse(raw);
        const answers = { ...reading, ...questions.success ? { questions: questions.data } : { questionsGap: "invalid" } };
        void native({ type: "answers", reading: answers }).catch(() => {
        });
        if (message.seq !== void 0) {
          const collection = collections.get(message.seq);
          if (collection) {
            clearTimeout(collection.timer);
            collections.delete(message.seq);
            collection.resolve(answers);
          }
        }
        break;
      }
      case "resize":
        frame.style.height = `${Math.max(48, Math.min(1e6, message.height))}px`;
        if (message.initialized) void native({ type: "drawn", height: message.height }).catch(() => {
        });
        break;
      case "pong":
        void native({ type: "pong", seq: message.seq }).catch(() => {
        });
        break;
      case "request": {
        const request = frameRequestSchema.safeParse(message);
        const reply = (ok, value2) => send({
          type: "response",
          document: documentID,
          id: message.id,
          ...ok ? { ok, result: value2 } : { ok, error: { code: "refused", message: String(value2) } }
        });
        if (!request.success || request.data.verb !== "action" || input.readOnly || !input.actions.includes(request.data.action)) {
          reply(false, "This card cannot do that.");
          return;
        }
        const value = request.data.value;
        if (value !== void 0 && new TextEncoder().encode(JSON.stringify(value)).length > ACTION_VALUE_MAX_BYTES) {
          reply(false, "The answer is too large.");
          return;
        }
        void native({ type: "action", id: request.data.action, value: value ?? null }).then((result) => reply(true, result), (error) => reply(false, error));
        break;
      }
      case "image": {
        if (!document.hasFocus() || !navigator.userActivation.isActive) return;
        const set = viewablePictures(message.index, message.pictures, !isPreviewBody(input.body));
        if (set) void native({ type: "image", ...set }).catch(() => {
        });
        break;
      }
      case "demo":
        if (document.hasFocus() && navigator.userActivation.isActive && demoSources(input.body).has(message.src) && viewablePictures(0, [message.poster]))
          void native({ type: "demo", src: message.src, poster: message.poster, caption: message.caption, play: message.play }).catch(() => {
          });
        break;
      // INF-1524: a link opens in the phone's own browser, a draft goes to the message box and a key opens its record.
      case "link":
        if (pressed() && isSafeCardHref(message.href)) void native({ type: "link", href: message.href }).catch(() => {
        });
        break;
      case "draft":
        if (pressed()) void native({ type: "draft", text: message.text }).catch(() => {
        });
        break;
      case "task":
        if (message.gesture === "open" && linked.includes(message.key)) void native({ type: "task", key: message.key }).catch(() => {
        });
        break;
      case "entry":
        void native({ type: "mac-only" }).catch(() => {
        });
        break;
    }
  });
  window.phoneCard = {
    async mount(value) {
      input = value;
      const split = value.card && takesTaskFacts(value.card) ? splitSettleFacts(value.body) : void 0;
      const marks = (value.marks ?? []).map((mark) => split && mark > split.at ? mark - split.facts.length : mark);
      linked = value.keys?.length ? taskKeysIn(value.body).filter((key) => value.keys.includes(key)) : [];
      void native({ type: "mounted", facts: split?.facts ?? null, preview: isPreviewBody(value.body) }).catch(() => {
      });
      const body = cardBodyMarkup(split?.body ?? value.body, marks).html;
      const parsed = new DOMParser().parseFromString(body, "text/html");
      const scripts = Array.from(parsed.querySelectorAll("script:not([src])"), (script) => script.textContent ?? "");
      const hashes = await native({ type: "hash", scripts });
      const document2 = buildFrameDocument({
        csp: `${frameCsp(hashes)}; base-uri 'none'; form-action 'none'`,
        theme: value.theme,
        style: cardStylesheet(),
        html: body
      });
      frame = window.document.createElement("iframe");
      frame.title = "Card body";
      frame.setAttribute("sandbox", FRAME_SANDBOX);
      frame.style.cssText = "display:block;width:100%;height:48px;border:0";
      frame.srcdoc = document2;
      window.document.body.replaceChildren(frame);
    },
    collect() {
      if (!documentID) return Promise.reject(fail("This card is still drawing. Try again once it is ready."));
      const seq = ++next;
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          collections.delete(seq);
          reject(fail("This card did not answer. Your choice was not sent."));
        }, 3e3);
        collections.set(seq, { resolve, reject, timer });
        send({ type: "collect", seq, focusUnpicked: true });
      });
    },
    theme(value) {
      send({ type: "theme", theme: value });
    },
    ping(seq) {
      send({ type: "ping", seq });
    }
  };
})();
