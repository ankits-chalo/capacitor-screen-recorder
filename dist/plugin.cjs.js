'use strict';

var core = require('@capacitor/core');

const ScreenRecorder = core.registerPlugin("ScreenRecorder", {
    web: () => Promise.resolve().then(function () { return web; }).then((m) => new m.ScreenRecorderWeb()),
});

class ScreenRecorderWeb extends core.WebPlugin {
    async start() {
        throw new Error("Method not implemented.");
    }
    async stop() {
        throw new Error("Method not implemented.");
    }
}

var web = /*#__PURE__*/Object.freeze({
    __proto__: null,
    ScreenRecorderWeb: ScreenRecorderWeb
});

exports.ScreenRecorder = ScreenRecorder;
//# sourceMappingURL=plugin.cjs.js.map
