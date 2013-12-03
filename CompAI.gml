#define CompAI
// BEGIN STATE CHECKING
//------------------------------------------------------------------
var global.AIState = 0; //Begin at Neutral State
for (i = 0; i < global.levelAmount; i+= 1) //For as long as the level Amount has not been hit
{
    var levelNum;
    levelNum = global.playerLevels[i]; //Search the levels close to the player
    for (j = 1; j <= global.nodeAmount; j+=1)
    {
        if (ds_map_exists(global.CP,j))
        then if (levelNum == ds_map_find_value(global.CP,j))
             then{
                  var search;
                  search = ds_map_find_value(global.nodeID,j);
                  if (search.Control == 2)
                  then global.AIState = 2; //If any of these levels is controlled by the computer, switch to Charge state
                 }
    }
    levelNum = global.computerLevels[i]; //Search the levels close to the computer
    for (j = global.nodeAmount; j > 0; j-=1)
    {
        if (ds_map_exists(global.CP,j))
        then if (levelNum == ds_map_find_value(global.CP,j))
             then{
                  var search;
                  search = ds_map_find_value(global.nodeID,j);
                  if (search.Control == 1)
                  then 
                  {
                       global.targetLv = search.level;
                       global.AIState = 1; //If any of these levels is controlled by the player, switch to Retreat state
                  }
                 }
    }
    if (global.AIState = 1) //If the state is Retreat, then exit the loop
    then i = global.levelAmount;
}
//END STATE CHECKING
//------------------------------------------------------------------

global.Step = 0;
var search;
var finish;
finish = 0;
var global.randNum = 0;
argument0.EUC = 0;

//BEGIN STEP CHECKING
//------------------------------------------------------------------
//Step 1: Is the player connected to your BC?
//-----------------------------------
//Searches all connections to BC
for (i = 1; i <= global.nodeAmount; i+=1)
{
    global.Step = 0;
    search = 1 << (i-1);
    argument0.thisNode = ds_map_find_value(global.nodeID,argument0.BC);
    if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
    then argument0.thatNode = ds_map_find_value(global.nodeID,i);
    else argument0.thatNode = 0;
    if argument0.thatNode != 0
    //If any connection is controlled by the player
    then if (argument0.thatNode.Control == 1)
         then global.Step = 1;
    if global.Step == 1    
    then //The player is connected to your BC
    //-----------------------------------
    {
        var connectionAmount;
        var connectionID; //Holds the ID number
        var connectUnits; //Holds the number of units in the node minus the number of units already sent to the node
        var squadNum;
        var thisSquad;
        var reinforcer;
        var attacked;
        attacked = -1;
        reinforcer = -1;
        connectionAmount = 0;
        argument0.EUC = 0;
        argument0.YUC = 0;
        //BEGIN SETTING THE ENEMY UNITS COMBINED
        //-----------------------------------
        //Find all connections to this node
        for (j = 0; j < global.nodeAmount; j+=1)
        {
            search = 1 << (j);
            if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
            then 
            {
                connectionID[connectionAmount] = ds_map_find_value(global.nodeID,j+1);
                connectUnits[connectionID[connectionAmount].NodeNum] = connectionID[connectionAmount].Units;
                connectionAmount += 1;
            }
        }
        //Search nodes connected to this node
        for (j = 0; j < connectionAmount; j+=1)
        {
            //If a connection is controlled by the player
            if (connectionID[j].Control == 1)
            then //The number of units in the node is added to the enemy units combined
                 argument0.EUC += connectionID[j].Units;
        }
        //Search the enemy units en route to this node from the connection
        squadNum = instance_number(objUnitRed);
        if (squadNum > 0)
        then for (j = 0; j < squadNum; j+=1)
             {
                thisSquad = instance_find(objUnitRed,j);
                //Check all squads moving towards the computer BC
                if (thisSquad.to == argument0.thisNode)
                then //The number of units in the squad is added to the enemy units combined
                {
                    argument0.EUC += thisSquad.unitNum;
                    connectUnits[thisSquad.from.NodeNum] += thisSquad.unitNum;
                }
             }
        //END SETTING THE ENEMY UNITS COMBINED
        //-----------------------------------
        //BEGIN SETTING THE YOUR UNITS COMBINED
        //-----------------------------------
        argument0.YUC += argument0.thisNode.Units;
        //Search the computer units en route to enemy nodes from this node
        squadNum = instance_number(objUnitBlue);
        if (squadNum > 0)
        then for (j = 0; j < squadNum; j+=1)
             {
                thisSquad = instance_find(objUnitBlue,j);
                //Search nodes connected to this node
                for (k = 0; k < connectionAmount; k+=1)
                {
                    //If a connection is controlled by the player
                    if (connectionID[k].Control == 1)
                    then //Check if the squad is moving towards this connection
                         if (thisSquad.to == connectionID[k])
                         then
                         {
                            //The units in that node are considered to be less
                            connectUnits[connectionID[k].NodeNum] -= thisSquad.unitNum;
                            //Check all squads moving away from the computer BC
                            if (thisSquad.from == argument0.thisNode)
                            then
                                //The number of units in the squad is added to the your units combined
                                argument0.YUC += thisSquad.unitNum;
                         }
                }
             }
        //END SETTING THE YOUR UNITS COMBINED
        //-----------------------------------
        //Enemy Units Combined greater than or equal to Your Units Combined?
        if (argument0.EUC >= argument0.YUC)
        then //Try to save the BC
        {
            //First search computer nodes connected to this node
            //and save the one with the highest unit number
            for (j = 0; j < connectionAmount; j+=1)
            {
                //If a connection is controlled by the computer
                if (connectionID[j].Control == 2)
                then
                {
                    var tempNode;
                    tempNode = connectionID[j];
                    //Save the node with the largest number of units as the reinforcer
                    if (reinforcer > -1)
                    then
                    {
                        if (tempNode.Units > reinforcer.Units)
                        then reinforcer = tempNode;
                    }
                    else reinforcer = tempNode;
                }
            }
            if reinforcer > -1
            then //Send reinforcements if a node is available
            {
                //The following will store global variables into temporary variables,
                //then change the global variables to the desired output. Then we will
                //call the script: "sendTroops" to send the reinforcements
                var tempFrom,tempTo,tempLeft,tempRight;
                tempFrom = global.from;
                tempTo = global.to;
                tempLeft = global.leftSelect;
                tempRight = global.rightSelect;
                global.from = reinforcer.NodeNum;
                global.to = argument0.thisNode.NodeNum;
                if (reinforcer.Units < 50)
                then
                {
                    global.leftSelect = 1;
                    global.rightSelect = 0;
                }
                else
                {
                    global.leftSelect = 0;
                    global.rightSelect = 1;
                }
                sendTroops();
                global.from = tempFrom;
                global.to = tempTo;
                global.leftSelect = tempLeft;
                global.rightSelect = tempRight;
                finish = 1;
            }
        }
        else //Invade the enemy nodes
        {
            //First search player nodes connected to this node
            //and save the one with the lowest unit number
            for (j = 0; j < connectionAmount; j+=1)
            {
                //If a connection is controlled by the player
                if (connectionID[j].Control == 1)
                then
                {
                    var tempNode;
                    tempNode = connectionID[j];
                    //Save the node with the smallest number of units as the attacked node
                    if (attacked > -1)
                    then
                    {
                        if (connectUnits[tempNode.NodeNum] > attacked.Units)
                        then attacked = tempNode;
                    }
                    else attacked = tempNode;
                }
            }
            if attacked > -1
            then //Send an invasion to the desired node
            {
                //The following will store global variables into temporary variables,
                //then change the global variables to the desired output. Then we will
                //call the script: "sendTroops" to send the reinforcements
                var tempFrom,tempTo,tempLeft,tempRight;
                tempFrom = global.from;
                tempTo = global.to;
                tempLeft = global.leftSelect;
                tempRight = global.rightSelect;
                global.from = argument0.thisNode.NodeNum;
                global.to = attacked.NodeNum;
                if (argument0.thisNode.Units < 50)
                then
                {
                    global.leftSelect = 1;
                    global.rightSelect = 0;
                }
                else
                {
                    global.leftSelect = 0;
                    global.rightSelect = 1;
                }
                sendTroops();
                global.from = tempFrom;
                global.to = tempTo;
                global.leftSelect = tempLeft;
                global.rightSelect = tempRight;
                finish = 1;
            }
        }
        break;
    }
}
if global.Step == 1
then
{
    var controlNum;
    controlNum = 0;
    for (i = global.nodeAmount; i >= 1; i-=1)
    {
        //If you are in control of the node
        argument0.thisNode = ds_map_find_value(global.nodeID,i);
        if argument0.thisNode.Control == 2
        then controlNum+=1;
    }
    if controlNum == 1
    then finish = 1;
}
if global.diff == 1
then global.randNum = random(2)
else if global.diff == 2
then global.randNum = random(6)
else global.randNum = random(11)
if (finish == 0 && (global.randNum >= 1))
then //Step 2: You connected to player BC?
//-----------------------------------
//Searches all connections to player BC
{
    for (i = 1; i <= global.nodeAmount; i+=1)
    {
        global.Step = 0;
        search = 1 << (i-1);
        if ((ds_map_find_value(global.mapNo,argument0.playerBC) & search) != 0)
        then argument0.thatNode = ds_map_find_value(global.nodeID,i);
        else argument0.thatNode = 0;
        if argument0.thatNode != 0
        //If any connection is controlled by you
        then if (argument0.thatNode.Control == 2)
             then
                global.Step = 2;
        if global.Step == 2
        then //You are connected to player BC
        //-----------------------------------
        {
            argument0.thisNode = ds_map_find_value(global.nodeID,argument0.playerBC);
            var connectionAmount;
            var connectionID; //Holds the ID number
            var connectUnits; //Holds the number of units in the node minus the number of units already sent to the node
            var squadNum;
            var thisSquad;
            var attacking;
            attacking = -1;
            connectionAmount = 0;
            argument0.EUC = 0;
            argument0.YUC = 0;
            //BEGIN SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //Find all connections to this node
            for (j = 0; j < global.nodeAmount; j+=1)
            {
                search = 1 << (j);
                if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                then 
                {
                    connectionID[connectionAmount] = ds_map_find_value(global.nodeID,j+1);
                    connectionAmount += 1;
                }
            }
            //Search nodes connected to this node
            for (j = 0; j < connectionAmount; j+=1)
            {
                //If a connection is controlled by the computer
                if (connectionID[j].Control == 2)
                then //The number of units in the node is added to the your units combined
                     argument0.YUC += connectionID[j].Units;
            }
            //Search the allied units en route to this node from the connection
            squadNum = instance_number(objUnitBlue);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitBlue,j);
                    //Check all squads moving towards the player BC
                    if (thisSquad.to == argument0.thisNode)
                    then //The number of units in the squad is added to the your units combined
                    {
                        argument0.YUC += thisSquad.unitNum;
                    }
                 }
            //END SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //BEGIN SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            argument0.EUC += argument0.thisNode.Units;
            //Search the computer units en route to enemy nodes from this node
            squadNum = instance_number(objUnitRed);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitRed,j);
                    //Search nodes connected to this node
                    for (k = 0; k < connectionAmount; k+=1)
                    {
                        //If a connection is controlled by the computer
                        if (connectionID[k].Control == 2)
                        then //Check if the squad is moving towards this connection
                             if (thisSquad.to == connectionID[k])
                             then
                             {
                                //Check if the squad is moving away from the player BC
                                if (thisSquad.from == argument0.thisNode)
                                then
                                    //The number of units in the squad is added to the your units combined
                                    argument0.EUC += thisSquad.unitNum;
                             }
                    }
                 }
            //END SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            //Enemy Units Combined is less than Your Units Combined?
            if (argument0.EUC < argument0.YUC)
            then //Invade the enemy nodes
            {
                //First search computer nodes connected to this node
                //and save the one with the highest unit number
                for (j = 0; j < connectionAmount; j+=1)
                {
                    //If a connection is controlled by the computer
                    if (connectionID[j].Control == 2)
                    then
                    {
                        var tempNode;
                        tempNode = connectionID[j];
                        //Save the node with the highest number of units as the attacking node
                        if (attacking > -1)
                        then
                        {
                            if (tempNode.Units > attacking.Units)
                            then attacking = tempNode;
                        }
                        else attacking = tempNode;
                    }
                }
                if attacking > -1
                then //Send an invasion to the desired node
                {
                    //The following will store global variables into temporary variables,
                    //then change the global variables to the desired output. Then we will
                    //call the script: "sendTroops" to send the reinforcements
                    var tempFrom,tempTo,tempLeft,tempRight;
                    tempFrom = global.from;
                    tempTo = global.to;
                    tempLeft = global.leftSelect;
                    tempRight = global.rightSelect;
                    global.from = attacking.NodeNum;
                    global.to = argument0.thisNode.NodeNum;
                    if (attacking.Units < 50)
                    then
                    {
                        global.leftSelect = 1;
                        global.rightSelect = 0;
                    }
                    else
                    {
                        global.leftSelect = 0;
                        global.rightSelect = 1;
                    }
                    sendTroops();
                    global.from = tempFrom;
                    global.to = tempTo;
                    global.leftSelect = tempLeft;
                    global.rightSelect = tempRight;
                    finish = 1;
                }
            }
            break;
        }
    }
}
if global.diff == 1
then global.randNum = random(2)
else if global.diff == 2
then global.randNum = random(6)
else global.randNum = random(11)
if (finish == 0 && (global.randNum >= 1))
then //Step 3: Player connected to CP you control?
//-----------------------------------
//Searches all CP's
{
    for (i = global.nodeAmount; i >= 1; i-=1)
    {
        global.Step = 0;
        if ds_map_exists(global.CP,i)
        then
        {
            //If you are in control of the CP
            argument0.thisNode = ds_map_find_value(global.nodeID,i);
            if argument0.thisNode.Control == 2
            then
            {
                //Checks all connections to the CP
                for (j = global.nodeAmount; j >= 1; j-=1)
                {
                    search = 1 << (j-1);
                    if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                    then argument0.thatNode = ds_map_find_value(global.nodeID,j);
                    else argument0.thatNode = 0;
                    if argument0.thatNode != 0
                    //If any connection is controlled by the player
                    then if (argument0.thatNode.Control == 1)
                         then
                            global.Step = 3;
                }
            }
        }
        if global.Step == 3
        then //The player is connected to a CP you control
        //-----------------------------------
        {
            var connectionAmount;
            var connectionID; //Holds the ID number
            var connectUnits; //Holds the number of units in the node minus the number of units already sent to the node
            var squadNum;
            var thisSquad;
            var reinforcer;
            var attacked;
            reinforcer = -1;
            attacked = -1;
            connectionAmount = 0;
            argument0.EUC = 0;
            argument0.YUC = 0;
            //BEGIN SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //Find all connections to this node
            for (j = 0; j < global.nodeAmount; j+=1)
            {
                search = 1 << (j);
                if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                then 
                {
                    connectionID[connectionAmount] = ds_map_find_value(global.nodeID,j+1);
                    connectUnits[connectionID[connectionAmount].NodeNum] = connectionID[connectionAmount].Units;
                    connectionAmount += 1;
                }
            }
            //Search nodes connected to this node
            for (j = 0; j < connectionAmount; j+=1)
            {
                //If a connection is controlled by the player
                if (connectionID[j].Control == 1)
                then //The number of units in the node is added to the enemy units combined
                     argument0.EUC += connectionID[j].Units;
            }
            //Search the enemy units en route to this node from the connection
            squadNum = instance_number(objUnitRed);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitRed,j);
                    //Check all squads moving towards the computer BC
                    if (thisSquad.to == argument0.thisNode)
                    then //The number of units in the squad is added to the enemy units combined
                    {
                        argument0.EUC += thisSquad.unitNum;
                        connectUnits[thisSquad.from.NodeNum] += thisSquad.unitNum;
                    }
                 }
            //END SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //BEGIN SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            argument0.YUC += argument0.thisNode.Units;
            //Search the computer units en route to enemy nodes from this node
            squadNum = instance_number(objUnitBlue);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitBlue,j);
                    //Search nodes connected to this node
                    for (k = 0; k < connectionAmount; k+=1)
                    {
                        //If a connection is controlled by the player
                        if (connectionID[k].Control == 1)
                        then //Check if the squad is moving towards this connection
                             if (thisSquad.to == connectionID[k])
                             then
                             {
                                //The units in that node are considered to be less
                                connectUnits[connectionID[k].NodeNum] -= thisSquad.unitNum;
                                //Check all squads moving away from the computer BC
                                if (thisSquad.from == argument0.thisNode)
                                then
                                    //The number of units in the squad is added to the your units combined
                                    argument0.YUC += thisSquad.unitNum;
                             }
                    }
                 }
            //END SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            //Enemy Units Combined greater than or equal to Your Units Combined?
            if (argument0.EUC < argument0.YUC)
            then //Invade the enemy nodes
            {
                if (global.AIState != 1)
                //First search player nodes connected to this node
                //and save the one with the lowest unit number
                then
                {
                     for (j = 0; j < connectionAmount; j+=1)
                     {
                        //If a connection is controlled by the player
                        if (connectionID[j].Control == 1)
                        then
                        {
                            var tempNode;
                            tempNode = connectionID[j];
                            //Save the node with the smallest number of units as the attacked node
                            if (attacked > -1)
                            then
                            {
                                if (connectUnits[tempNode.NodeNum] > attacked.Units)
                                then attacked = tempNode;
                            }
                            else attacked = tempNode;
                        }
                     }
                     if attacked > -1
                     then //Send an invasion to the desired node
                     {
                        //The following will store global variables into temporary variables,
                        //then change the global variables to the desired output. Then we will
                        //call the script: "sendTroops" to send the reinforcements
                        var tempFrom,tempTo,tempLeft,tempRight;
                        tempFrom = global.from;
                        tempTo = global.to;
                        tempLeft = global.leftSelect;
                        tempRight = global.rightSelect;
                        global.from = argument0.thisNode.NodeNum;
                        global.to = attacked.NodeNum;
                        if (argument0.thisNode.Units < 50)
                        then
                        {
                            global.leftSelect = 1;
                            global.rightSelect = 0;
                        }
                        else
                        {
                            global.leftSelect = 0;
                            global.rightSelect = 1;
                        }
                        sendTroops();
                        global.from = tempFrom;
                        global.to = tempTo;
                        global.leftSelect = tempLeft;
                        global.rightSelect = tempRight;
                        finish = 1;
                     }
                }
            }
        }
        if finish == 1
        then break;
    }
}
if global.diff == 1
then global.randNum = random(2)
else if global.diff == 2
then global.randNum = random(6)
else global.randNum = random(11)
if (finish == 0 && (global.randNum >= 1))
then //Step 4: You connected to CP you don't control?
//-----------------------------------
//Searches all CP's
{
    for (i = global.nodeAmount; i >= 1; i-=1)
    {
        global.Step = 0;
        if ds_map_exists(global.CP,i)
        then
        {
            //If you are not in control of the CP
            argument0.thisNode = ds_map_find_value(global.nodeID,i);
            if argument0.thisNode.Control != 2
            then
            {
                //Checks all connections to the CP
                for (j = global.nodeAmount; j >= 1; j-=1)
                {
                    search = 1 << (j-1);
                    if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                    then argument0.thatNode = ds_map_find_value(global.nodeID,j);
                    else argument0.thatNode = 0;
                    if argument0.thatNode != 0
                    //If any connection is controlled by you
                    then if (argument0.thatNode.Control == 2)
                         then
                            global.Step = 4;
                }
            }
        }
        if global.Step == 4
        then
        //You are connected to a CP you don't control
        //-----------------------------------
        {
            var connectionAmount;
            var connectionID; //Holds the ID number
            var connectUnits; //Holds the number of units in the node minus the number of units already sent to the node
            var squadNum;
            var thisSquad;
            var attacking;
            attacking = -1;
            connectionAmount = 0;
            argument0.EUC = 0;
            argument0.YUC = 0;
            //BEGIN SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            //Find all connections to this node
            for (j = 0; j < global.nodeAmount; j+=1)
            {
                search = 1 << (j);
                if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                then 
                {
                    connectionID[connectionAmount] = ds_map_find_value(global.nodeID,j+1);
                    connectionAmount += 1;
                }
            }
            //Search nodes connected to this node
            for (j = 0; j < connectionAmount; j+=1)
            {
                //If a connection is controlled by the computer
                if (connectionID[j].Control == 2)
                then //The number of units in the node is added to the your units combined
                     argument0.YUC += connectionID[j].Units;
            }
            //Search the allied units en route to this node from the connection
            squadNum = instance_number(objUnitBlue);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitBlue,j);
                    //Check all squads moving towards the player BC
                    if (thisSquad.to == argument0.thisNode)
                    then //The number of units in the squad is added to the your units combined
                    {
                        argument0.YUC += thisSquad.unitNum;
                    }
                 }
            //END SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            //BEGIN SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            argument0.EUC += argument0.thisNode.Units;
            //Search the computer units en route to enemy nodes from this node
            squadNum = instance_number(objUnitRed);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitRed,j);
                    //Search nodes connected to this node
                    for (k = 0; k < connectionAmount; k+=1)
                    {
                        //If a connection is controlled by the computer
                        if (connectionID[k].Control == 2)
                        then //Check if the squad is moving towards this connection
                             if (thisSquad.to == connectionID[k])
                             then
                             {
                                //Check if the squad is moving away from the player node
                                if (thisSquad.from == argument0.thisNode)
                                then
                                    //The number of units in the squad is added to the your units combined
                                    argument0.EUC += thisSquad.unitNum;
                             }
                    }
                 }
            //END SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //Enemy Units Combined is less than Your Units Combined?
            if (argument0.EUC < argument0.YUC)
            then //Invade the enemy nodes
            {
                //First search computer nodes connected to this node
                //and save the one with the highest unit number
                for (j = 0; j < connectionAmount; j+=1)
                {
                    //If a connection is controlled by the computer
                    if (connectionID[j].Control == 2)
                    then
                    {
                        var tempNode;
                        tempNode = connectionID[j];
                        //Save the node with the highest number of units as the attacking node
                        if (attacking > -1)
                        then
                        {
                            if (tempNode.Units > attacking.Units)
                            then attacking = tempNode;
                        }
                        else attacking = tempNode;
                    }
                }
                if attacking > -1
                then //Send an invasion to the desired node
                {
                    //The following will store global variables into temporary variables,
                    //then change the global variables to the desired output. Then we will
                    //call the script: "sendTroops" to send the reinforcements
                    var tempFrom,tempTo,tempLeft,tempRight;
                    tempFrom = global.from;
                    tempTo = global.to;
                    tempLeft = global.leftSelect;
                    tempRight = global.rightSelect;
                    global.from = attacking.NodeNum;
                    global.to = argument0.thisNode.NodeNum;
                    if (attacking.Units < 50)
                    then
                    {
                        global.leftSelect = 1;
                        global.rightSelect = 0;
                    }
                    else
                    {
                        global.leftSelect = 0;
                        global.rightSelect = 1;
                    }
                    sendTroops();
                    global.from = tempFrom;
                    global.to = tempTo;
                    global.leftSelect = tempLeft;
                    global.rightSelect = tempRight;
                    finish = 1;
                }
            }
        }
        if finish == 1
        then break;
    }
}
if global.diff == 1
then global.randNum = random(2)
else if global.diff == 2
then global.randNum = random(6)
else global.randNum = random(11)
if (finish == 0 && (global.randNum >= 1))
then //Step 5: One of your nodes has a unit number exceeding 75?
//-----------------------------------
{
    var noGood; //Holds the ID numbers of nodes that should not send troops
    var counter;
    var found;
    var connectionAmount;
    var connectionID; //Holds the ID number
    var controlNum;
    controlNum = 0;
    counter = 0;
    found = false;
    for (i = global.nodeAmount; i >= 1; i-=1)
    {
        //If you are in control of the node
        argument0.thisNode = ds_map_find_value(global.nodeID,i);
        if argument0.thisNode.Control == 2
        then controlNum+=1;
    }
    counterTwo = 0;
    argument0.thisNode = -1;
    argument0.thatNode = -1;
    while (!found)
    {
        connectionAmount = 0;
        argument0.thisNode = -1;
        argument0.thatNode = -1;
        for (i = global.nodeAmount; i >= 1; i-=1)
        {
            counterTwo += 1;
            var restart;
            restart = true;
            while (restart)
            {
                var k;
                k = i;
                for(j = 0; j < counter; j+=1)
                {
                    if (i == noGood[j])
                    then
                    {
                        i-=1;
                        j = counter
                    }
                }
                if k == i
                then restart = false;
            }
            if (i != argument0.playerBC || global.AIState == 1)
            then
            {   
                var tempNode;
                //If you are in control of the node
                tempNode = ds_map_find_value(global.nodeID,i);
                if (tempNode.Control == 2)
                then
                {
                    if argument0.thisNode > -1
                    then
                    {
                        if (tempNode.Units > argument0.thisNode.Units)
                        then argument0.thisNode = tempNode;
                    }
                    else argument0.thisNode = tempNode;
                }
            }
        }
        if argument0.thisNode != -1
        then{
                if argument0.thisNode.Units > 75
                then global.Step = 5;
                else found = true;
            }
        else{
                global.Step = 0;
                if counterTwo >= global.nodeAmount
                then found = true;
            }
        if global.Step == 5
        then
        {
            //Find all connections to this node
            for (i = 0; i < global.nodeAmount; i+=1)
            {
                search = 1 << (i);
                if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                then 
                {
                    connectionID[connectionAmount] = ds_map_find_value(global.nodeID,i+1);
                    connectionAmount += 1;
                }
            }
            if (global.AIState == 1)
            then //Send the unit towards target
            {
                //Search nodes connected to this node
                for (i = 0; i < connectionAmount; i+=1)
                {
                    //If a connection's level is lower than this node's
                    if (((global.targetLv < argument0.thisNode.level
                    && connectionID[i].level < argument0.thisNode.level)
                    || (global.targetLv > argument0.thisNode.level
                    && connectionID[i].level > argument0.thisNode.level))
                    && connectionID[i].Control == 2)
                    then
                    {
                        if (argument0.thatNode > -1)
                        then
                        {
                            if (connectionID[i].Units <= argument0.thatNode.Units)
                               then argument0.thatNode = connectionID[i];
                        }
                        else argument0.thatNode = connectionID[i];
                    }
                }
            }
            else //Send the unit forwards
            {
                //Search nodes connected to this node
                for (i = 0; i < connectionAmount; i+=1)
                {
                    //If a connection's level is higher than this node's
                    if (connectionID[i].level > argument0.thisNode.level
                    && connectionID[i].Control == 2)
                    then
                    {
                        if (argument0.thatNode > -1)
                        then
                        {
                            if (connectionID[i].Units <= argument0.thatNode.Units)
                               then argument0.thatNode = connectionID[i];
                        }
                        else argument0.thatNode = connectionID[i];
                    }
                }
            }
            if argument0.thatNode != -1
            then
            {
                //Send units
                //The following will store global variables into temporary variables,
                //then change the global variables to the desired output. Then we will
                //call the script: "sendTroops" to send the reinforcements
                var tempFrom,tempTo,tempLeft,tempRight;
                tempFrom = global.from;
                tempTo = global.to;
                tempLeft = global.leftSelect;
                tempRight = global.rightSelect;
                global.from = argument0.thisNode.NodeNum;
                global.to = argument0.thatNode.NodeNum;
                if (argument0.thisNode.Units < 50)
                then
                {
                    global.leftSelect = 1;
                    global.rightSelect = 0;
                }
                else
                {
                    global.leftSelect = 0;
                    global.rightSelect = 1;
                }
                sendTroops();
                global.from = tempFrom;
                global.to = tempTo;
                global.leftSelect = tempLeft;
                global.rightSelect = tempRight;
                finish = 1;
                found = true;
            }
            else
            {
                noGood[counter] = argument0.thisNode.NodeNum;
                counter+=1;
            }
            if (controlNum == counter)
            then found = true;
        }
    }
}
if global.diff == 1
then global.randNum = random(2)
else if global.diff == 2
then global.randNum = random(6)
else global.randNum = random(11)
if (finish == 0 && (global.randNum >= 1))
then //Step 6: You connected to a node you don't control?
//-----------------------------------
//Searches all nodes
{
    for (i = global.nodeAmount; i >= 1; i-=1)
    {
        global.Step = 0;
        //If you are in control of the node
        argument0.thatNode = ds_map_find_value(global.nodeID,i);
        if argument0.thatNode.Control == 2
        { //Checks all connections to the node
                 for (j = global.nodeAmount; j >= 1; j-=1)
                 {
                    search = 1 << (j-1);
                    if ((ds_map_find_value(global.mapNo,argument0.thatNode.NodeNum) & search) != 0)
                    then argument0.thisNode = ds_map_find_value(global.nodeID,j);
                    else argument0.thisNode = 0;
                    if argument0.thisNode != 0
                    //If any connection is controlled by nobody
                    then if (argument0.thisNode.Control == 0)
                         then
                         {
                             global.Step = 6;
                             j = 0;
                         }
                 }
        }
        if global.Step == 6
        then //You are connected to a node you don't control
        //-----------------------------------
        {
            var connectionAmount;
            var connectionID; //Holds the ID number
            var connectUnits; //Holds the number of units in the node minus the number of units already sent to the node
            var squadNum;
            var thisSquad;
            var attacking;
            attacking = -1;
            connectionAmount = 0;
            argument0.EUC = 0;
            argument0.YUC = 0;
            //BEGIN SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //Find all connections to this node
            for (j = 0; j < global.nodeAmount; j+=1)
            {
                search = 1 << (j);
                if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                then 
                {
                    connectionID[connectionAmount] = ds_map_find_value(global.nodeID,j+1);
                    connectionAmount += 1;
                }
            }
            //Search nodes connected to this node
            for (j = 0; j < connectionAmount; j+=1)
            {
                //If a connection is controlled by the computer
                if (connectionID[j].Control == 2)
                then //The number of units in the node is added to the your units combined
                     argument0.YUC += connectionID[j].Units;
            }
            //Search the allied units en route to this node from the connection
            squadNum = instance_number(objUnitBlue);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitBlue,j);
                    //Check all squads moving towards the player BC
                    if (thisSquad.to == argument0.thisNode)
                    then //The number of units in the squad is added to the your units combined
                    {
                        argument0.YUC += thisSquad.unitNum;
                    }
                 }
            //END SETTING THE ENEMY UNITS COMBINED
            //-----------------------------------
            //BEGIN SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            argument0.EUC += argument0.thisNode.Units;
            //Search the computer units en route to enemy nodes from this node
            squadNum = instance_number(objUnitRed);
            if (squadNum > 0)
            then for (j = 0; j < squadNum; j+=1)
                 {
                    thisSquad = instance_find(objUnitRed,j);
                    //Search nodes connected to this node
                    for (k = 0; k < connectionAmount; k+=1)
                    {
                        //If a connection is controlled by the computer
                        if (connectionID[k].Control == 2)
                        then //Check if the squad is moving towards this connection
                             if (thisSquad.to == connectionID[j])
                             then
                             {
                                //Check if the squad is moving away from the player BC
                                if (thisSquad.from == argument0.thisNode)
                                then
                                    //The number of units in the squad is added to the your units combined
                                    argument0.EUC += thisSquad.unitNum;
                             }
                    }
                 }
            //END SETTING THE YOUR UNITS COMBINED
            //-----------------------------------
            //Enemy Units Combined is less than Your Units Combined?
            if (argument0.EUC < argument0.YUC)
            then //Invade the enemy nodes
            {
                //First search computer nodes connected to this node
                //and save the one with the highest unit number
                for (j = 0; j < connectionAmount; j+=1)
                {
                    //If a connection is controlled by the computer
                    if (connectionID[j].Control == 2)
                    then
                    {
                        var tempNode;
                        tempNode = connectionID[j];
                        //Save the node with the highest number of units as the attacking node
                        if (attacking > -1)
                        then
                        {
                            if (tempNode.Units > attacking.Units)
                            then attacking = tempNode;
                        }
                        else attacking = tempNode;
                    }
                }
                if attacking > -1
                then //Send an invasion to the desired node
                {
                    //The following will store global variables into temporary variables,
                    //then change the global variables to the desired output. Then we will
                    //call the script: "sendTroops" to send the reinforcements
                    var tempFrom,tempTo,tempLeft,tempRight;
                    tempFrom = global.from;
                    tempTo = global.to;
                    tempLeft = global.leftSelect;
                    tempRight = global.rightSelect;
                    global.from = attacking.NodeNum;
                    global.to = argument0.thisNode.NodeNum;
                    if (attacking.Units < 50)
                    then
                    {
                        global.leftSelect = 1;
                        global.rightSelect = 0;
                    }
                    else
                    {
                        global.leftSelect = 0;
                        global.rightSelect = 1;
                    }
                    sendTroops();
                    global.from = tempFrom;
                    global.to = tempTo;
                    global.leftSelect = tempLeft;
                    global.rightSelect = tempRight;
                    finish = 1;
                }
            }
        }
        if finish == 1
        then break;
    }
}
if global.diff == 1
then global.randNum = random(2)
else if global.diff == 2
then global.randNum = random(6)
else global.randNum = random(11)
if (finish == 0 && (global.randNum >= 1))
then //Step 7: Send any possible reinforcements
//-----------------------------------
{
    var noGood; //Holds the ID numbers of nodes that should not send troops
    var counter;
    var found;
    var connectionAmount;
    var connectionID; //Holds the ID number
    var controlNum;
    controlNum = 0;
    counter = 0;
    found = false;
    for (i = global.nodeAmount; i >= 1; i-=1)
    {
        //If you are in control of the node
        argument0.thisNode = ds_map_find_value(global.nodeID,i);
        if argument0.thisNode.Control == 2
        then controlNum+=1;
    }
    counterTwo = 0;
    while (!found)
    {
        connectionAmount = 0;
        argument0.thisNode = -1;
        argument0.thatNode = -1;
        for (i = global.nodeAmount; i >= 1; i-=1)
        {
            counterTwo +=1;
            var restart;
            restart = true;
            while (restart)
            {
                var k;
                k = i;
                for(j = 0; j < counter; j+=1)
                {
                    if (i == noGood[j])
                    then
                    {
                        i-=1;
                        j = counter
                    }
                }
                if k == i
                then restart = false;
            }
            if (i != argument0.playerBC || global.AIState == 1)
            then
            {
                var tempNode;
                //If you are in control of the node
                tempNode = ds_map_find_value(global.nodeID,i);
                if (tempNode.Control == 2)
                then
                {
                    if argument0.thisNode > -1
                    then
                    {
                        if (tempNode.Units > argument0.thisNode.Units)
                        then argument0.thisNode = tempNode;
                    }
                    else argument0.thisNode = tempNode;
                }               
            }
        }
        if argument0.thisNode != -1
        then global.Step = 7;
        else{
                global.Step = 0;
                if counterTwo >= global.nodeAmount
                then found = true;
            }
        if global.Step == 7
        then
        {
            //Find all connections to this node
            for (i = 0; i < global.nodeAmount; i+=1)
            {
                search = 1 << (i);
                if ((ds_map_find_value(global.mapNo,argument0.thisNode.NodeNum) & search) != 0)
                then 
                {
                    connectionID[connectionAmount] = ds_map_find_value(global.nodeID,i+1);
                    connectionAmount += 1;
                }
            }
            if (global.AIState == 1)
            then //Send the unit towards target
            {
                //Search nodes connected to this node
                for (i = 0; i < connectionAmount; i+=1)
                {
                    //If a connection's level is lower than this node's
                    if (((global.targetLv < argument0.thisNode.level
                    && connectionID[i].level < argument0.thisNode.level)
                    || (global.targetLv > argument0.thisNode.level
                    && connectionID[i].level > argument0.thisNode.level))
                    && connectionID[i].Control == 2)
                    then
                    {
                        if (argument0.thatNode > -1)
                        then
                        {
                            if (connectionID[i].Units <= argument0.thatNode.Units)
                               then argument0.thatNode = connectionID[i];
                        }
                        else argument0.thatNode = connectionID[i];
                    }
                }
            }
            else //Send the unit forwards
            {
                //Search nodes connected to this node
                for (i = 0; i < connectionAmount; i+=1)
                {
                    //If a connection's level is higher than this node's
                    if (connectionID[i].level > argument0.thisNode.level
                    && connectionID[i].Control == 2)
                    then
                    {
                        if (argument0.thatNode > -1)
                        then
                        {
                            if (connectionID[i].Units <= argument0.thatNode.Units)
                               then argument0.thatNode = connectionID[i];
                        }
                        else argument0.thatNode = connectionID[i];
                    }
                }
            }
            if argument0.thatNode != -1
            then
            {
                //Send units
                //The following will store global variables into temporary variables,
                //then change the global variables to the desired output. Then we will
                //call the script: "sendTroops" to send the reinforcements
                var tempFrom,tempTo,tempLeft,tempRight;
                tempFrom = global.from;
                tempTo = global.to;
                tempLeft = global.leftSelect;
                tempRight = global.rightSelect;
                global.from = argument0.thisNode.NodeNum;
                global.to = argument0.thatNode.NodeNum;
                if (argument0.thisNode.Units < 50)
                then
                {
                    global.leftSelect = 1;
                    global.rightSelect = 0;
                }
                else
                {
                    global.leftSelect = 0;
                    global.rightSelect = 1;
                }
                sendTroops();
                global.from = tempFrom;
                global.to = tempTo;
                global.leftSelect = tempLeft;
                global.rightSelect = tempRight;
                finish = 1;
                found = true;
            }
            else
            {
                noGood[counter] = argument0.thisNode.NodeNum;
                counter+=1;
            }
            if (controlNum == counter)
            then found = true;
        }
    }
}
//END STEP CHECKING
//------------------------------------------------------------------

