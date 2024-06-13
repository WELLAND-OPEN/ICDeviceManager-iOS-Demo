//
//  ViewController.m
//  ICDMDemo
//
//  Created by Symons on 2018/8/1.
//  Copyright © 2018年 Symons. All rights reserved.
//

#import "ViewController.h"
#import <ICDeviceManager/ICDeviceManager.h>

@interface ViewController () <ICDeviceManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UITextView *txtResult;
@property (weak, nonatomic) IBOutlet UIButton *btnSetUnit;
@property (weak, nonatomic) IBOutlet UIPickerView *picker;
@property (weak, nonatomic) IBOutlet UIButton *btnSetCal;
@property (weak, nonatomic) IBOutlet UITextField *txtValue;
@property (weak, nonatomic) IBOutlet UIButton *btnDel;
@property (weak, nonatomic) IBOutlet UIButton *btnSelect;
@property (weak, nonatomic) IBOutlet UITextField *txtPassword;
@property (weak, nonatomic) IBOutlet UIButton *btnWifi;

@end

@implementation ViewController
{
    ICScanDeviceInfo *_deviceInfo;
    NSDictionary<NSNumber *, NSArray<NSString *> *> *_units;
    NSInteger _unitIndex;
    ICDevice *device;

}
- (IBAction)configWifiEvent:(id)sender {
    // Config Wifi
    NSString *ssid = _txtValue.text;
    NSString *pwd = _txtPassword.text;
    [[[ICDeviceManager shared] getSettingManager]  configWifi:device mode:ICConfigWifiModeDefault ssid:ssid password:pwd callback:^(ICSettingCallBackCode code) {
        _txtResult.text = [NSString stringWithFormat:@"%@\r\n config wifi code=%d", _txtResult.text, code];

    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // user info
    ICUserInfo *userInfo = [ICUserInfo new];
    userInfo.age = 34;
    userInfo.height = 178;
    userInfo.sex = ICSexTypeMale;
    userInfo.userIndex = 1;
    userInfo.weightUnit = ICWeightUnitKg;
    userInfo.rulerUnit = ICRulerUnitCM;
    userInfo.kitchenUnit = ICKitchenScaleUnitG;
    userInfo.peopleType = ICPeopleTypeNormal;
    
  
    [[ICDeviceManager shared] updateUserInfo:userInfo];
    
    
    
    
    
    
    // demo
    _units =@{
              @(0) : @[@"kg", @"jin", @"lb"],
              @(1) : @[@"g", @"oz"],
              @(2) : @[@"cm", @"inch"]
              };
    _unitIndex = -1;
    _picker.delegate = self;
    _picker.dataSource = self;
    _txtResult.editable = NO;
    _btnWifi.enabled = NO;
    _txtResult.layoutManager.allowsNonContiguousLayout = NO;

    device = [ICDevice new];
    // init SDK
    [ICDeviceManager shared].delegate = self;
    [[ICDeviceManager shared] initMgr];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotify:) name:@"SCAN_RESULT" object:nil];
    
    
}
- (IBAction)clickDel:(id)sender {
    if (device) {
        [[ICDeviceManager shared] removeDevice:device callback:^(ICDevice *device, ICRemoveDeviceCallBackCode code) {
            
        }];
    }
    _btnSelect.enabled = YES;
    _btnDel.enabled = NO;
}

- (IBAction)clickSetCal:(id)sender {
    
    [[[ICDeviceManager shared] getSettingManager] setNutritionFacts:device type:ICKitchenScaleNutritionFactTypeCalorie value:_txtValue.text.integerValue callback:^(ICSettingCallBackCode code) {
        _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@ %d", _txtResult.text, @"callback state :", code];

    }];
}

- (IBAction)clickUnit:(id)sender {
    [_picker reloadAllComponents];
    _picker.hidden = NO;
}

- (void)onNotify:(NSNotification *)notify
{
    if ([notify.name isEqualToString:@"SCAN_RESULT"]) {
        _deviceInfo = (ICScanDeviceInfo *)notify.object;
        
        if (_deviceInfo.type == ICDeviceTypeRuler) {
            _unitIndex = 2;
            _btnSetCal.enabled = NO;
        }
        else if (_deviceInfo.type == ICDeviceTypeKitchenScale) {
            _unitIndex = 1;
            _btnSetCal.enabled = YES;
        }
        else if (_deviceInfo.type == ICDeviceTypeFatScale || _deviceInfo.type == ICDeviceTypeFatScaleWithTemperature) {
            _unitIndex = 0;
            _btnSetCal.enabled = NO;
        }
        else {
            _unitIndex = -1;
            _btnSetCal.enabled = NO;
        }
        
        device.macAddr = _deviceInfo.macAddr;
        _btnSelect.enabled = NO;
        _btnDel.enabled = YES;

        [[ICDeviceManager shared] addDevice:device callback:^(ICDevice *device, ICAddDeviceCallBackCode code) {
            if (code == ICAddDeviceCallBackCodeSuccess) {
                NSLog(@"Add Success");
            }
            else {
               NSLog(@"Add Failed");
            }
        }];
    }
}

- (void)onBleState:(ICBleState)state
{
    NSString *stateStr = @"no open";
    if (state == ICBleStatePoweredOn) {
        stateStr = @"ble enable";
    }
    else if (state == ICBleStateUnauthorized) {
        stateStr = @"no authorized";
    }
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, stateStr];;
}

- (void)onInitFinish:(BOOL)bSuccess
{
    _txtResult.text = [NSString stringWithFormat:@"SDK init %@", bSuccess ? @"success" : @"fail"];
}

- (void)onDeviceConnectionChanged:(ICDevice *)device state:(ICDeviceConnectState)state
{
    if (_unitIndex >= 0) {
        if (state == ICDeviceConnectStateConnected) {
            _btnSetUnit.enabled = YES;
        }
        else {
            _btnSetUnit.enabled = NO;
        }
    }
    if (state == ICDeviceConnectStateConnected) {
        // check device type
        if (_deviceInfo.subType == ICDeviceSubTypeScaleDual) {
            _btnWifi.enabled = YES;
        }
        else{
            _btnWifi.enabled = NO;

        }
    }
    else {
        _btnWifi.enabled = NO;
    }
     NSString *t = [NSString stringWithFormat:@"%@ %@", device.macAddr, state == ICDeviceConnectStateConnected ? @"Connected" : @"Disconnected"];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}



- (void)onReceiveWeightData:(ICDevice *)device data:(ICWeightData *)data
{
    NSString *t = [NSString stringWithFormat:@"%@ weight data :%.2f kg,imp=%@, %@", device.macAddr, data.weight_kg, data.impendences, data.isStabilized ? @"stabilized" : @"not stabilized"];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveRulerData:(ICDevice *)device data:(ICRulerData *)data
{
     NSString *t = [NSString stringWithFormat:@"%@ ruler data :%.2fcm, %lu %@", device.macAddr, data.distance_cm, data.time, data.isStabilized ? @"stabilized" : @"not stabilized"];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
    if (data.isStabilized) {
        if (data.partsType != ICRulerPartsTypeCalf) {
            // auto change body parts type
            [[[ICDeviceManager shared] getSettingManager] setRulerBodyPartsType:device type:data.partsType + 1 callback:^(ICSettingCallBackCode code) {
                // NSLog(@"set result = %d", code);
            }];
        }
    }
}

- (void)onReceiveCoordData:(ICDevice *)device data:(ICCoordData *)data
{
     NSString *t = [NSString stringWithFormat:@"%@ coord data (%d, %d)", device.macAddr, data.x, data.y];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];

}

- (void)onReceiveKitchenScaleData:(ICDevice *)device data:(ICKitchenScaleData *)data
{
     NSString *t = [NSString stringWithFormat:@"%@ kitchen data %0.2f %@", device.macAddr, data.value_g, data.isStabilized ? @"stabilized" : @"not stabilized"];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveKitchenScaleUnitChanged:(ICDevice *)device unit:(ICKitchenScaleUnit)unit
{
      NSString *t = [NSString stringWithFormat:@"%@ kitchen scale unit changed %d", device.macAddr, unit];
     _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveWeightCenterData:(ICDevice *)device data:(ICWeightCenterData *)data
{
    NSString *t = [NSString stringWithFormat:@"%@ center data (%d, %d)", device.macAddr, data.leftPercent, data.rightPercent];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveWeightUnitChanged:(ICDevice *)device unit:(ICWeightUnit)unit
{
    NSString *t = [NSString stringWithFormat:@"%@ weight unit changed %d", device.macAddr, unit];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveRulerUnitChanged:(ICDevice *)device unit:(ICRulerUnit)unit
{
    NSString *t = [NSString stringWithFormat:@"%@ ruler unit changed %d", device.macAddr, unit];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveRulerMeasureModeChanged:(ICDevice *)device mode:(ICRulerMeasureMode)mode
{
    NSString *t = [NSString stringWithFormat:@"%@ ruler measure mode changed %d", device.macAddr, mode];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

- (void)onReceiveElectrodeData:(ICDevice *)device data:(ICElectrodeData *)data
{
    _txtValue.text = [NSString stringWithFormat:@"%d,%d,%d,%d", data.weightLT_kg, data.weightLB_kg, data.weightRT_kg, data.weightRB_kg];
    NSString *t = [NSString stringWithFormat:@"%@ electrode data %d,%d,%d,%d", device.macAddr, data.weightLT_kg, data.weightLB_kg, data.weightRT_kg, data.weightRB_kg];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
}

// eight eletrode scale
- (void)onReceiveMeasureStepData:(ICDevice *)device step:(ICMeasureStep)step data:(NSObject *)data2
{
    switch (step) {
        case ICMeasureStepMeasureWeightData:
        {
            ICWeightData *data = (ICWeightData *)data2;
            [self onReceiveWeightData:device data:data];
        }
            break;
        case ICMeasureStepMeasureCenterData:
        {
            ICWeightCenterData *data = (ICWeightCenterData *)data2;
            [self onReceiveWeightCenterData:device data:data];
        }
            break;
        case ICMeasureStepAdcStart:
        {
            NSString *t = [NSString stringWithFormat:@"%@ start adc", device.macAddr];
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
            
        }
            break;
        case ICMeasureStepAdcResult:
        {
            NSString *t = [NSString stringWithFormat:@"%@ stop adc", device.macAddr];
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
            
        }
            break;
        case ICMeasureStepHrStart:
        {
            NSString *t = [NSString stringWithFormat:@"%@ start hr", device.macAddr];
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
            
        }
            break;
            
        case ICMeasureStepHrResult:
        {
            ICWeightData *hrData = (ICWeightData *)data2;
            NSString *t = [NSString stringWithFormat:@"%@ stop hr, %lu", device.macAddr, (unsigned long)hrData.hr];
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
            
        }
            break;
        case ICMeasureStepMeasureOver:
        {
            NSString *t = [NSString stringWithFormat:@"%@ stop measure", device.macAddr];
            ICWeightData *data = (ICWeightData *)data2;
            data.isStabilized = YES;
            [self onReceiveWeightData:device data:data];
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];
            
        }
            break;
            
        default:
            break;
    }
}

- (void)onReceiveWeightHistoryData:(ICDevice *)device data:(ICWeightHistoryData *)data
{
    NSString *t = [NSString stringWithFormat:@"%@ history data %.2f", device.macAddr, data.weight_kg];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, t];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (_unitIndex < 0) {
        return 0;
    }
    NSInteger count = _units[@(_unitIndex)].count;
    return count;
}


- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _units[@(_unitIndex)][row];
    
}

// 当用户选中UIPickerViewDataSource中指定列和列表项时激发该方法
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    _picker.hidden = YES;
    NSString *unitStr =  _units[@(_unitIndex)][row];
    if (_unitIndex == 0) {
        ICWeightUnit unit = ICWeightUnitJin;
        if ([unitStr isEqualToString:@"kg"]) {
            unit = ICWeightUnitKg;
        }
        if ([unitStr isEqualToString:@"lb"]) {
            unit = ICWeightUnitLb;
        }
        if ([unitStr isEqualToString:@"jin"]) {
            unit = ICWeightUnitJin;
        }
        [[[ICDeviceManager shared] getSettingManager] setScaleUnit:device unit:unit callback:^(ICSettingCallBackCode code) {
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@ %d", _txtResult.text, @"code :", code];
        }];
    }
    else if (_unitIndex == 1) {
        ICKitchenScaleUnit unit = ICKitchenScaleUnitG;
        if ([unitStr isEqualToString:@"oz"]) {
            unit = ICKitchenScaleUnitOz;
        }
        if ([unitStr isEqualToString:@"g"]) {
            unit = ICKitchenScaleUnitG;
        }
        [[[ICDeviceManager shared] getSettingManager] setKitchenScaleUnit:device unit:unit callback:^(ICSettingCallBackCode code) {
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@ %d", _txtResult.text, @"code :", code];
        }];
    }
    else if (_unitIndex == 2) {
        ICRulerUnit unit = ICRulerUnitInch;
        if ([unitStr isEqualToString:@"cm"]) {
            unit = ICRulerUnitCM;
        }
        if ([unitStr isEqualToString:@"inch"]) {
            unit = ICRulerUnitInch;
        }
        [[[ICDeviceManager shared] getSettingManager] setRulerUnit:device unit:unit callback:^(ICSettingCallBackCode code) {
            _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@ %d", _txtResult.text, @"code :", code];
        }];
    }
}

- (void)onReceiveSkipData:(ICDevice *)device data:(ICSkipData *)data
{
    NSString *str = [NSString stringWithFormat:@"skip data: mode=%d, param=%d,elapsed time=%d,skip count=%d\r\n", data.mode, data.setting, data.elapsed_time, data.skip_count];
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n%@", _txtResult.text, str];
}

- (void)onReceiveHistorySkipData:(ICDevice *)device data:(ICSkipData *)data
{
    
}

- (void)onReceiveSkipBattery:(ICDevice *)device battery:(NSUInteger)battery
{
    
}

- (void)onReceiveUpgradePercent:(ICDevice *)device status:(ICUpgradeStatus)status percent:(NSUInteger)percent
{
    
}

- (void)onReceiveConfigWifiResult:(ICDevice *)device state:(ICConfigWifiState)state
{
    _txtResult.text = [NSString stringWithFormat:@"%@\r\n config wifi callback state=%d", _txtResult.text, state];

}


@end
