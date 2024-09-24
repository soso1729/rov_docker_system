
"use strict";

let InitRectTrajectory = require('./InitRectTrajectory.js')
let InitWaypointsFromFile = require('./InitWaypointsFromFile.js')
let GetWaypoints = require('./GetWaypoints.js')
let SwitchToAutomatic = require('./SwitchToAutomatic.js')
let GetSMControllerParams = require('./GetSMControllerParams.js')
let GetMBSMControllerParams = require('./GetMBSMControllerParams.js')
let SetPIDParams = require('./SetPIDParams.js')
let AddWaypoint = require('./AddWaypoint.js')
let GetPIDParams = require('./GetPIDParams.js')
let GoToIncremental = require('./GoToIncremental.js')
let SwitchToManual = require('./SwitchToManual.js')
let InitWaypointSet = require('./InitWaypointSet.js')
let SetMBSMControllerParams = require('./SetMBSMControllerParams.js')
let ClearWaypoints = require('./ClearWaypoints.js')
let Hold = require('./Hold.js')
let SetSMControllerParams = require('./SetSMControllerParams.js')
let ResetController = require('./ResetController.js')
let StartTrajectory = require('./StartTrajectory.js')
let InitHelicalTrajectory = require('./InitHelicalTrajectory.js')
let GoTo = require('./GoTo.js')
let InitCircularTrajectory = require('./InitCircularTrajectory.js')
let IsRunningTrajectory = require('./IsRunningTrajectory.js')

module.exports = {
  InitRectTrajectory: InitRectTrajectory,
  InitWaypointsFromFile: InitWaypointsFromFile,
  GetWaypoints: GetWaypoints,
  SwitchToAutomatic: SwitchToAutomatic,
  GetSMControllerParams: GetSMControllerParams,
  GetMBSMControllerParams: GetMBSMControllerParams,
  SetPIDParams: SetPIDParams,
  AddWaypoint: AddWaypoint,
  GetPIDParams: GetPIDParams,
  GoToIncremental: GoToIncremental,
  SwitchToManual: SwitchToManual,
  InitWaypointSet: InitWaypointSet,
  SetMBSMControllerParams: SetMBSMControllerParams,
  ClearWaypoints: ClearWaypoints,
  Hold: Hold,
  SetSMControllerParams: SetSMControllerParams,
  ResetController: ResetController,
  StartTrajectory: StartTrajectory,
  InitHelicalTrajectory: InitHelicalTrajectory,
  GoTo: GoTo,
  InitCircularTrajectory: InitCircularTrajectory,
  IsRunningTrajectory: IsRunningTrajectory,
};
