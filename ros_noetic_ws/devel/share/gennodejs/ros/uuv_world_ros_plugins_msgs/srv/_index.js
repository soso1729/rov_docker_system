
"use strict";

let SetCurrentDirection = require('./SetCurrentDirection.js')
let SetCurrentModel = require('./SetCurrentModel.js')
let TransformToSphericalCoord = require('./TransformToSphericalCoord.js')
let TransformFromSphericalCoord = require('./TransformFromSphericalCoord.js')
let GetCurrentModel = require('./GetCurrentModel.js')
let SetOriginSphericalCoord = require('./SetOriginSphericalCoord.js')
let GetOriginSphericalCoord = require('./GetOriginSphericalCoord.js')
let SetCurrentVelocity = require('./SetCurrentVelocity.js')

module.exports = {
  SetCurrentDirection: SetCurrentDirection,
  SetCurrentModel: SetCurrentModel,
  TransformToSphericalCoord: TransformToSphericalCoord,
  TransformFromSphericalCoord: TransformFromSphericalCoord,
  GetCurrentModel: GetCurrentModel,
  SetOriginSphericalCoord: SetOriginSphericalCoord,
  GetOriginSphericalCoord: GetOriginSphericalCoord,
  SetCurrentVelocity: SetCurrentVelocity,
};
