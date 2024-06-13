//
//  SelectDeviceTableViewController.m
//  ICDMDemo
//
//  Created by Symons on 2018/8/31.
//  Copyright © 2018年 Symons. All rights reserved.
//

#import "SelectDeviceTableViewController.h"
#import <ICDeviceManager/ICDeviceManager.h>

@interface SelectDeviceTableViewController () <UITableViewDelegate, UITableViewDataSource, ICScanDeviceDelegate>

@end

@implementation SelectDeviceTableViewController
{
    NSMutableArray<ICScanDeviceInfo *> *_items;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _items = [NSMutableArray arrayWithCapacity:4];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[ICDeviceManager shared] scanDevice:self];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [[ICDeviceManager shared] stopScan];
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onScanResult:(ICScanDeviceInfo *)deviceInfo
{
    BOOL isE = NO;
    for (ICScanDeviceInfo *devic in _items) {
        if ([devic.macAddr isEqualToString:deviceInfo.macAddr]) {
            isE = YES;
            break;
        }
    }
    if (!isE) {
        [_items addObject:deviceInfo];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"scancell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    
    ICScanDeviceInfo *deviceInfo = _items[indexPath.row];
    
    // 3.覆盖数据
    cell.textLabel.text = [NSString stringWithFormat:@"%@\t%@\t%d", deviceInfo.name, deviceInfo.macAddr, deviceInfo.rssi];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SCAN_RESULT" object:_items[indexPath.row]];
    [self.navigationController popViewControllerAnimated:YES];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
