//
//  KBAdvPacketSensor.m
//  KBeaconConfig
//
//  Created by kkm on 2019/7/22.
//  Copyright © 2019 kkm. All rights reserved.
//

#import "KBAdvPacketSensor.h"

#define MIN_SENSOR_ADV_HEAD_LEN 2

#define SENSOR_MASK_VOLTAGE 0x1
#define SENSOR_MASK_TEMP 0x2
#define SENSOR_MASK_HUME 0x4
#define SENSOR_MASK_ACC_AIX 0x8
@implementation KBAccSensorValue
@end

@implementation KBAdvPacketSensor
-(BOOL) parseAdvPacket:(const NSData*) data
{
    [super parseAdvPacket:data];
    
    int nSrvIndex = 0;
    Byte* pSrvData = (Byte*)[data bytes];
    
    //frame type
    if (pSrvData[nSrvIndex++] != 0x21)
    {
        return NO;
    }
    
    if (data.length < MIN_SENSOR_ADV_HEAD_LEN)
    {
        return NO;
    }
    
    //version
    _version = [NSNumber numberWithInt: (int)pSrvData[nSrvIndex++]];
    
    //sensor mask
    Byte bySensorMask = pSrvData[nSrvIndex++];
    if (bySensorMask & SENSOR_MASK_VOLTAGE)
    {
        if (nSrvIndex > data.length - 2)
        {
            return NO;
        }
        
        int nBatteryLvs = (pSrvData[nSrvIndex++] & 0xFF);
        nBatteryLvs = (nBatteryLvs << 8);
        nBatteryLvs += (pSrvData[nSrvIndex++] & 0xFF);
        
        _batteryLevel = [NSNumber numberWithInt:nBatteryLvs];
    }
    
    if (bySensorMask & SENSOR_MASK_TEMP)
    {
        if (nSrvIndex > data.length - 2)
        {
            return NO;
        }
        
        int nTempPointLeft = (char)pSrvData[nSrvIndex++];
        float nTempPointRight = ((float)pSrvData[nSrvIndex++]) / 256;
        float nTempRsult = nTempPointLeft + nTempPointRight;
        NSString* strTemp = [NSString stringWithFormat:@"%.2f",nTempRsult];
        _temperature = [NSNumber numberWithFloat:[strTemp floatValue]];
    }
    
    if (bySensorMask & SENSOR_MASK_HUME)
    {
        if (nSrvIndex > data.length - 2)
        {
            return NO;
        }
        
        int nHumPointLeft = (Byte)(pSrvData[nSrvIndex++] & 0xFF);
        int nHumPointRight = (pSrvData[nSrvIndex++] & 0xFF);
        NSString* strTemp = [NSString stringWithFormat:@"%d.%d", nHumPointLeft, nHumPointRight];
        _humidity = [NSNumber numberWithFloat:[strTemp floatValue]];
    }
    
    if (bySensorMask & SENSOR_MASK_ACC_AIX)
    {
        if (nSrvIndex > data.length - 6)
        {
            return NO;
        }
        
        _accSensor = [[KBAccSensorValue alloc]init];
        short nAccValue = (short)((pSrvData[nSrvIndex++] & 0xFF) << 8);
        nAccValue += (short)(pSrvData[nSrvIndex++] & 0xFF);
        _accSensor.xAis = [NSNumber numberWithInt:nAccValue];
        
        nAccValue = (short)((pSrvData[nSrvIndex++] & 0xFF) << 8);
        nAccValue += (pSrvData[nSrvIndex++] & 0xFF);
        _accSensor.yAis = [NSNumber numberWithInt:nAccValue];

        nAccValue = (short)((pSrvData[nSrvIndex++] & 0xFF) << 8);
        nAccValue += (pSrvData[nSrvIndex++] & 0xFF);
        _accSensor.zAis = [NSNumber numberWithInt:nAccValue];
    }
    
    return YES;
}



@end
