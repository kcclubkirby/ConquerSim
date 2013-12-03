#define Initialize
global.milli = 0;
global.sec = 0;
global.minutes = 0;
global.hr = 0;

draw_set_halign(fa_center);
draw_set_valign(fa_middle);

var global.win = 0;
var global.from = 0;
var global.to = 0;
var global.leftSelect = 0;
var global.rightSelect = 0;
var global.charge = 0;
var global.nodeAmount = 16
//This establishes the different connections
var global.mapNo = ds_map_create();
ds_map_add(global.mapNo,1,6);
ds_map_add(global.mapNo,2,49);
ds_map_add(global.mapNo,3,49);
ds_map_add(global.mapNo,4,656);
ds_map_add(global.mapNo,5,174);
ds_map_add(global.mapNo,6,342);
ds_map_add(global.mapNo,7,4384);
ds_map_add(global.mapNo,8,1560);
ds_map_add(global.mapNo,9,6240);
ds_map_add(global.mapNo,10,1160);
ds_map_add(global.mapNo,11,27264);
ds_map_add(global.mapNo,12,29952);
ds_map_add(global.mapNo,13,2368);
ds_map_add(global.mapNo,14,35840);
ds_map_add(global.mapNo,15,35840);
ds_map_add(global.mapNo,16,24576);

//This map saves the node ID numbers for each node
var global.nodeID = ds_map_create();

//THE FOLLOWING INITIALIZATIONS ARE FOR THE COMPUTER AI
//This map saves all CP nodes, along with their level numbers
var global.CP = ds_map_create();
var global.levelAmount = 2
var global.computerLevels[0] = 1;
var global.computerLevels[1] = 2;
var global.playerLevels[0] = 4;
var global.playerLevels[1] = 5;

