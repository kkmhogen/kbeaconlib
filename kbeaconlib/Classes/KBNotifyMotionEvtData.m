//
//  KBNotifyMotionEvtData.m
//  kbeaconlib
//
//  Created by hogen on 2021/1/30.
//

#import "KBNotifyMotionEvtData.h"


@implementation KBNotifyMotionEvtData


-(NSNumber*) getSensorDataType
{
    return [NSNumber numberWithInt: KBNotifyDataTypeButton];
}

-(void)parseSensorDataResponse:(KBeacon*)beacon data:(NSData*)sensorDataNtf;
{
    if (sensorDataNtf == nil || sensorDataNtf.length < 2)
    {
        return;
    }

    const Byte* pByte = [sensorDataNtf bytes];
    if (pByte[0] != KBNotifyDataTypeButton)
    {
        return;
    }

    _motionNtfEvent = [NSNumber numberWithInt: pByte[1]];
}


@end
