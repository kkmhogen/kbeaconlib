//
//  KBProximityDataMsg.m
//  KBeacon
//
//  Created by hogen on 2020/5/23.
//  Copyright © 2020 hogen. All rights reserved.
//

#import "KBProximityDataMsg.h"
#import "UTCTime.h"
#import "KBProximityRecord.h"

#define NB_INFO_RSP_LENGTH 6

@implementation KBProximityInfoRsp
@end
@implementation KBProximityDataRsp
@end

@implementation KBProximityDataMsg
{
    long utcSecondsOffset;
}

-(int)getSensorDataType
{
    return KBSensorDataTypeProxmity;
}

-(NSData*) makeReadSensorDataReq:(long)nReadRcdNo order:(int)nReadOrder
readNumber:( int) nMaxRecordNum
{
    Byte byMsgReq[7];
    int nIndex = 0;

    //read pos
    byMsgReq[nIndex++] = (Byte)((nReadRcdNo >> 24) & 0xFF);
    byMsgReq[nIndex++] = (Byte)((nReadRcdNo >> 16) & 0xFF);
    byMsgReq[nIndex++] = (Byte)((nReadRcdNo >> 8) & 0xFF);
    byMsgReq[nIndex++] = (Byte)(nReadRcdNo  & 0xFF);

    //read num
    byMsgReq[nIndex++] = (Byte)((nMaxRecordNum >> 8) & 0xFF);
    byMsgReq[nIndex++] = (Byte)(nMaxRecordNum & 0xFF);

    //read direction
    byMsgReq[nIndex] = (Byte)nReadOrder;
    
    NSData* data = [[NSData alloc]initWithBytes:(void*)byMsgReq length:7];
    return data;
}


-(void) parseSensorInfoResponse:(KBeacon*) beacon dataPtr:(int)dataPtr
response:(NSData*)sensorInfoRsp
{
    if (sensorInfoRsp.length - dataPtr < 6)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"sensor info response is null", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (self->mCmdSensorCallback != nil)
        {
            onReadSensorComplete tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(false, nil, error);
        }
        return;
    }

    const Byte* pSensorInfoReq = [sensorInfoRsp bytes];
    int nIndex = dataPtr;
    
    //get record number
    KBProximityInfoRsp* infoRsp = [[KBProximityInfoRsp alloc]init];
    int nRecordNum = htons(*(unsigned short*)&pSensorInfoReq[nIndex]);
    nIndex += 2;
    infoRsp.readInfoRecordNumber = [NSNumber numberWithInt:nRecordNum];
    
    //get utc count
    long nUtcSeconds = htonl(*(long*)&pSensorInfoReq[nIndex]);
    infoRsp.readInfoUtcSeconds = [NSNumber numberWithLong:nUtcSeconds];
    
    //get utc offset
    self->utcSecondsOffset = [UTCTime getUTCTimeSecond] - nUtcSeconds;
    
    if (self->mCmdSensorCallback != nil)
    {
        onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
        self->mCmdSensorCallback = nil;
        tempCallback(true, infoRsp, nil);
    }
    return;
}

-(void) parseSensorDataResponse:(KBeacon*)beacon dataPtr:(int)dataPtr
  response:(NSData*)sensorDataRsp
{
    //sensor data type
    const Byte* pRspData = [sensorDataRsp bytes];
    int nReadIndex = dataPtr;
    
    //read data tag
    if (pRspData[nReadIndex] != KBSensorDataTypeProxmity)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"sensor data response is null", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (self->mCmdSensorCallback != nil)
        {
            onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(false, nil, error);
        }
        return;
    }
    nReadIndex++;

    //read next data pos
    unsigned int nNextPos = htonl(*(unsigned int*)&pRspData[nReadIndex]);
    nReadIndex += 4;

    //check payload length valid
    unsigned long nPayLoad = sensorDataRsp.length - nReadIndex;
    if (nPayLoad % 12 != 0)
    {
        NSDictionary *userInfo1 = [NSDictionary dictionaryWithObjectsAndKeys:@"sensor data response is invalid", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"",NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError* error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:KBEvtCfgFailed userInfo:userInfo1];
        
        if (self->mCmdSensorCallback != nil)
        {
            onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
            self->mCmdSensorCallback = nil;
            tempCallback(false, nil, error);
        }
        return;
    }

    KBProximityDataRsp* pDataRsp = [[KBProximityDataRsp alloc]init];
    pDataRsp.readDataList = [[NSMutableArray alloc]init];
    pDataRsp.readDataNextNum = [NSNumber numberWithInt:nNextPos];
    
    //read record
    int nRecordStartPtr = nReadIndex;
    int nTotalRecordLen = (int)nPayLoad / 12;
    for (int i = 0; i < nTotalRecordLen; i++)
    {
        int nRecordPtr = nRecordStartPtr + i * 12;
        KBProximityRecord* record = [[KBProximityRecord alloc]init];
        
        //nearby time
        record.nearbyTime = [NSNumber numberWithInt:pRspData[nRecordPtr++]];
        
        //mac address;
        Byte byMacAddress[3];
        byMacAddress[0] = pRspData[nRecordPtr++];
        byMacAddress[1] = pRspData[nRecordPtr++];
        byMacAddress[2] = pRspData[nRecordPtr++];
        
        NSString* strMacPrefex = [beacon.mac substringToIndex:8];
        NSData* pDMacTail = [[NSData alloc]initWithBytes:(void*)byMacAddress length:3];
        NSString* strMacTail = [KBUtility bytesToHexString:pDMacTail];
        if (strMacTail != nil)
        {
            record.mac = [NSString stringWithFormat:@"%@:%@:%@:%@",
                         strMacPrefex,
                        [strMacTail substringWithRange:(NSRange){0,2}],
                          [strMacTail substringWithRange:(NSRange){2,2}],
                          [strMacTail substringWithRange:(NSRange){4,2}]];
        }
        
        //utc time
        long nUtcTime = htonl(*(unsigned int*)&pRspData[nRecordPtr]);
        nRecordPtr += 4;
        record.utcTime = [NSNumber numberWithLong:nUtcTime];

        //major
        unsigned short nMajorID = htons(*(unsigned short*)&pRspData[nRecordPtr]);
        nRecordPtr += 2;
        record.majorID = [NSNumber numberWithInt:nMajorID];
        
        //minor
        unsigned short nMinorID = htons(*(unsigned short*)&pRspData[nRecordPtr]);
        nRecordPtr += 2;
        record.minorID = [NSNumber numberWithInt:nMinorID];

        [pDataRsp.readDataList addObject:record];
    }

    if (self->mCmdSensorCallback != nil)
    {
        onSensorDataCommandCallback tempCallback = self->mCmdSensorCallback;
        self->mCmdSensorCallback = nil;
        tempCallback(true, pDataRsp, nil);
    }
}

@end
