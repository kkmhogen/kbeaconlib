//
//  KBCfgSensor.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/29.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBCfgSensor.h"
#import "KBException.h"

#define JSON_FIELD_TYPE_ENABLE_SENSOR "sensor"

@implementation KBCfgSensor

-(KBConfigType) cfgParaType
{
    return KBConfigTypeSensor;
}

-(void)setSensorType:(NSNumber*) sensorType
{
    int nTmpSensorType = [sensorType intValue];
    if (nTmpSensorType != 0
        && (nTmpSensorType & KBSensorTypeAcc) == 0
        && (nTmpSensorType & KBSensorTypeHumidity) == 0)
    {
        @throw [[KBException alloc] init:KBEvtCfgInputInvalid info:@"sensor type invalid"];
    }
    else
    {
        _sensorType = sensorType;
    }
}

-(int) updateConfig:(NSDictionary*)dicts
{
    if ([dicts objectForKey:JSON_FIELD_SENSOR_TYPE] != nil)
    {
        _sensorType = [dicts objectForKey:JSON_FIELD_SENSOR_TYPE];
        return 1;
    }
    
    return 0;
}

+(NSString*)getSensorTypeString:(NSNumber*) nSensorType
{
    if ([nSensorType intValue] == 1)
    {
        return SENSOR_TYPE_ACC_POSITION;
    }
    else if ([nSensorType intValue] == 0)
    {
        return @"none";
    }
    else
    {
        return @"unknown";
    }
}


-(NSMutableDictionary*) toDictionary
{
    NSMutableDictionary* configDicts = [[NSMutableDictionary alloc]initWithCapacity:2];
    
    if (_sensorType != nil)
    {
        [configDicts setObject:_sensorType forKey:JSON_FIELD_SENSOR_TYPE];
    }
    
    return configDicts;
}

@end
