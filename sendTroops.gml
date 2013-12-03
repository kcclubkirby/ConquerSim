#define sendTroops
var search;
var from;
var to;
var units;
var squad;
var instNum;

search = 1 << (global.to - 1);
if ((ds_map_find_value(global.mapNo,global.from) & search) != 0)
then {
      from = ds_map_find_value(global.nodeID,global.from);
      to = ds_map_find_value(global.nodeID,global.to);
      if (from.Units > 1)
      then {
            if (global.leftSelect == 1)
            then units = from.Units - 1;
            else units = from.Units div 2;
            from.Units -= units;
            if (from.Control == 1)
            then {instNum = instance_number(objUnitRed);
                  instance_create(from.x, from.y, objUnitRed);
                  squad = instance_find(objUnitRed,instNum);
                  global.watch = instance_position(from.x, from.y, objUnitRed);
                 }
            else if (from.Control == 2)
            then {instNum = instance_number(objUnitBlue);
                  instance_create(from.x, from.y, objUnitBlue);
                  squad = instance_find(objUnitBlue,instNum);
                  global.watch = instance_position(from.x, from.y, objUnitBlue);
                 }
            squad.unitNum = units;
            squad.Control = from.Control;
            if (from.Control == 1)
            then {if (squad.unitNum <= 49)
                  then squad.sprite_index = sprRedUnitSmall;
                  else squad.sprite_index = sprRedUnitLarge;
                 }
            else if (from.Control == 2)
            then {if (squad.unitNum <= 49)
                  then squad.sprite_index = sprBlueUnitSmall;
                  else squad.sprite_index = sprBlueUnitLarge;
                 }
            squad.to = to;
            squad.from = from;
            if units > 100
            then squad.speed = 0.25;
            else squad.speed =  ((-4.5) * (units-1) / 99) + 5;
            squad.dirX = to.x-squad.x;
            squad.dirY = -(to.y-squad.y);
            if squad.dirX = 0
            then {
                  if squad.dirY > 0
                  then squad.direction = 90;
                  else squad.direction = 270;
                 }
            else squad.direction = (arctan(squad.dirY/squad.dirX)) * 180 / pi;
            if (squad.dirX < 0)
            then squad.direction += 180; 
            }
      }

