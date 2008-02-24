//
//  WSOSCMessage.m
//  WSOSC
//
//  Created by Woon Seung Yeo on Fri Mar 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "WSOSCMessage.h"


@implementation WSOSCMessage

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeBool:_hasTypeTag forKey:@"OSCMessageHasTypeTag"];
    [coder encodeObject:_addressString forKey:@"OSCAddressString"];
	[coder encodeObject:_addressPattern forKey:@"OSCAddressPattern"];
	[coder encodeObject:_typeTagString forKey:@"OSCTypeTagString"];
	[coder encodeObject:_arguments forKey:@"OSCArguments"];
}

- (id)initWithCoder:(NSCoder *)coder {
	if (self = [super init]) {
        _hasTypeTag = [coder decodeBoolForKey:@"OSCMessageHasTypeTag"];
        _addressString = [coder decodeObjectForKey:@"OSCAddressString"];
        _addressPattern = [coder decodeObjectForKey:@"OSCAddressPattern"];
        _typeTagString = [coder decodeObjectForKey:@"OSCTypeTagString"];
        _arguments = [coder decodeObjectForKey:@"OSCArguments"];
        
        [_addressString retain];
        [_addressPattern retain];
        [_typeTagString retain];
        [_arguments retain];
    }
    return self;
}

- (void)dealloc {
    [_addressString release];
    [_addressPattern release];
    [_typeTagString release];
    [_arguments release];
    [super dealloc];
}

- (id)init {
    if (self = [super init]) {
        _hasTypeTag = YES;
        _addressString = [[NSString alloc] init];
        _addressPattern = [[NSMutableArray alloc] init];
        _typeTagString = [[NSString alloc] init];
        _arguments = [[NSMutableArray alloc] init];
    }
	return self;
}


- (id)initWithDataFrom:(NSData *)data {
    if (self = [super init]) {
        _hasTypeTag = YES;
        _addressString = [[NSString alloc] init];
        _addressPattern = [[NSMutableArray alloc] init];
        _typeTagString = [[NSString alloc] init];
        _arguments = [[NSMutableArray alloc] init];
        [self parseFrom:data];
    }
	return self;
}

+ (id)messageParsedFrom:(NSData *)data {
    return [[[self alloc] initWithDataFrom:data] autorelease];
}

- (void)parseFrom:(NSData *)data {
    // Variables necessary for parsing arguments
    int32_t argumentInt32;
    float_t argumentFloat32;
	NSSwappedFloat float32Bits;
    NSString *argumentString;

    int index;
    
    // Parse address pattern
	int nullOffset = [self byteOffSet:'\0' inData:data];
    _addressString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0,nullOffset)] 
										   encoding:NSUTF8StringEncoding];
   /// _addressString = [[data componentsSeparatedByString:@"\0"] objectAtIndex:0];
    _addressPattern = [_addressString pathComponents];
    
    // Parse typetag string
    int32_t typeTagIndex = [_addressString length] + (4 - ([_addressString length]%4) + 1);
    NSData *tagsAndArguments = [data subdataWithRange:NSMakeRange(typeTagIndex,[data length] - typeTagIndex)];

    // Parse typeTag
	nullOffset = [self byteOffSet:'\0' inData:tagsAndArguments];
	_typeTagString = [[NSString alloc] initWithData:[tagsAndArguments subdataWithRange:NSMakeRange(0,nullOffset)] 
										   encoding:NSUTF8StringEncoding];
       //_typeTagString = [[tagsAndArguments componentsSeparatedByString:@"\0"] objectAtIndex:0];
    int pointer = 
        ([_typeTagString length]+1) + (4 - ( ([_typeTagString length]+1) % 4 ) - 1);
    
    for (index = 0; index < [_typeTagString length]; index++) {
        switch ([_typeTagString characterAtIndex:index]) {
			case 'f':
                //argumentChar = (char *)[tagsAndArguments subdataWithRange:NSMakeRange(pointer,4)];
				//argumentFloat32 = (float *)argumentChar;
				[tagsAndArguments getBytes:&float32Bits range:NSMakeRange(pointer, 4)];
				argumentFloat32 = NSSwapBigFloatToHost(float32Bits);
                [_arguments addObject:[NSNumber numberWithFloat:argumentFloat32]];
                pointer += 4;
				break;
			case 'i':
				[tagsAndArguments getBytes:&argumentInt32 range:NSMakeRange(pointer, 4)];
                //argumentInt32 = (int *)[tagsAndArguments subdataWithRange:NSMakeRange(pointer,4)];
				argumentInt32 = EndianS32_BtoN(argumentInt32);
                [_arguments addObject:[NSNumber numberWithInt:argumentInt32]];
                pointer += 4;
				break;
			case 's':
				nullOffset = [self byteOffSet:'\0' inData:[tagsAndArguments subdataWithRange:NSMakeRange(pointer,[tagsAndArguments length] - pointer)]];
                argumentString = 
				[[NSString alloc] initWithData:[tagsAndArguments subdataWithRange:NSMakeRange(pointer,nullOffset)] 
									  encoding:NSUTF8StringEncoding];
				if (argumentString == nil) {
					printf("found null");
				}
				//argumentString = [[argumentString componentsSeparatedByString:@"\0"] objectAtIndex:0];
               // [[[tagsAndArguments substringFromIndex:pointer]
                [_arguments addObject:argumentString];
                pointer += [argumentString length] + 4 - ([argumentString length]%4);
                break;

            // From here, types not implemented yet...
			case 'b':
                //arguments = [arguments stringByAppendingString:@", <OSC-blob>"];
                //pointer += 4;
				break;
            case 'h':
                //arguments = [arguments stringByAppendingString:@", <64 bit big-endian two's complement integer>"];
                //pointer += 4;
                break;
            case 't':
                //arguments = [arguments stringByAppendingString:@", <OSC-timetag>"];
                //pointer += 4;
                break;
            case 'd':
                //arguments = [arguments stringByAppendingString:@", <64 bit IEEE 754 floating point>"];
                //pointer += 4;
                break;
            case 'S':
                //arguments = [arguments stringByAppendingString:@", <Alternate type represented as an OSC-string>"];
                //pointer += 4;
                break;
            case 'c':
                //arguments = [arguments stringByAppendingString:@", <32 bit ASCII character>"];
                //pointer += 4;
                break;
            case 'r':
                //arguments = [arguments stringByAppendingString:@", <32 bit RGBA color>"];
                //pointer += 4;
                break;
            case 'm':
                //arguments = [arguments stringByAppendingString:@", <4 byte MIDI message>"];
                //pointer += 4;
                break;
            case 'T':
                //arguments = [arguments stringByAppendingString:@", <True>"];
                //pointer += 4;
                break;
            case 'F':
                //arguments = [arguments stringByAppendingString:@", <False>"];
                //pointer += 4;
                break;
            case 'N':
                //arguments = [arguments stringByAppendingString:@", <Nil>"];
                //pointer += 4;
                break;
            case 'I':
                //arguments = [arguments stringByAppendingString:@", <Infinitum>"];
                //pointer += 4;
                break;
            case '[':
                //arguments = [arguments stringByAppendingString:@", ["];
                //pointer += 4;
                break;
            case ']':
                //arguments = [arguments stringByAppendingString:@", ]"];
                //pointer += 4;
                break;
		}
    }
}    

- (int)byteOffSet:(char) toFind inData:(NSData*) data {
	int counter = 0, length = [data length];
	const char * dataBytes = [data bytes];
	
	while(counter <= length) {
		if (dataBytes[counter]  == toFind) {
			return counter;
		} else {
			counter++;
		}
	}
	return -1;
}


- (BOOL)hasTypeTag {
    return _hasTypeTag;
}

- (NSString *)addressString {
    return _addressString;
}

- (NSArray *)addressPattern {
    return _addressPattern;
}

- (NSString *)typeTagString {
    return _typeTagString;
}

- (NSMutableArray *)arguments {
    return _arguments;
}

- (int)numberOfAddressPatterns {
    return [_addressPattern count];
}

- (NSString *)addressPatternAtIndex:(int)index {
    return [_addressPattern objectAtIndex:index];
}

- (char)typeTagAtIndex:(int)index {
    return [_typeTagString characterAtIndex:index];
}

- (int)numberOfArguments {
    return [_arguments count];
}

- (id)argumentAtIndex:(int)index {
    return [_arguments objectAtIndex:index];
}

@end
