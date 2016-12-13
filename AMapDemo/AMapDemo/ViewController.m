//
//  ViewController.m
//  AMapDemo
//
//  Created by MAC on 2016/12/12.
//  Copyright © 2016年 MAC. All rights reserved.
//

#import "ViewController.h"
#import <AMapSearchKit/AMapSearchKit.h>
#import <MAMapKit/MAMapKit.h>
#import "CloudPOIAnnotation.h"
#import "APIKey.h"


#define kCloudSearchCity @"南宁"
@interface ViewController ()<MAMapViewDelegate,AMapSearchDelegate>
{
    // 当前定位到的坐标点
    CLLocationCoordinate2D currentCoordinate;
}

@property (strong, nonatomic) MAMapView *mapView;
@property (strong, nonatomic) AMapSearchAPI *searchAPI;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMapView];
    [self initSearchAPI];

}

- (void) initMapView {
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.mapType = MAMapTypeStandard; // 普通地图
    self.mapView.showsUserLocation = YES;   //YES 为打开定位，NO为关闭定位
    self.mapView.showsCompass = NO;
    self.mapView.showsScale = NO;
    self.mapView.userTrackingMode = 0; // 追踪用户地理位置更新
    self.mapView.zoomLevel = 16.1;
    self.mapView.alpha = 0.8;
    [self.view addSubview:self.mapView];
}

- (void) initSearchAPI {
    self.searchAPI = [[AMapSearchAPI alloc]init];
    self.searchAPI.delegate = self;
    self.searchAPI.language = AMapSearchLanguageZhCN;
}

// 发起逆向地址编码
- (void)searchLocationWithCoordinate2D:(CLLocationCoordinate2D )coordinate {
    //构造AMapReGeocodeSearchRequest对象
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    regeo.radius = 10000;
    regeo.requireExtension = YES;
    
    //发起逆地理编码
    [self.searchAPI AMapReGoecodeSearch: regeo];
}

#pragma mark - MAMapViewDelegate
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
    if(updatingLocation){
        //取出当前位置的坐标
        currentCoordinate = userLocation.coordinate;
        
        CLLocationCoordinate2D myCoordinate = currentCoordinate;
        MACoordinateRegion theRegion = MACoordinateRegionMake(myCoordinate, MACoordinateSpanMake(0.2, 0.2));
        [self.mapView setScrollEnabled:YES];
        [self.mapView setRegion:theRegion animated:YES];
        [self.mapView setZoomLevel:16.1 animated:NO];
        
        // 停止定位
        self.mapView.showsUserLocation = NO;
        
        // 以当前的定位点为中心点发起云检索
        [self searchLocationWithCoordinate2D:currentCoordinate];
        
    }
}

- (void)mapView:(MAMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"%@",error);
}

#pragma mark - AMapSearchDelegate
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if(response.regeocode != nil)
    {
        //通过AMapReGeocodeSearchResponse对象处理搜索结果
        NSString *city = response.regeocode.addressComponent.city;
        if (!city || [city length] == 0) {
            city = response.regeocode.addressComponent.province; // 直辖市时获取此字段
        }
        
        //self.city = city;
    }
}


#pragma mark - Utility

- (void)addAnnotationsWithPOIs:(NSArray *)pois
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for (AMapCloudPOI *aPOI in pois)
    {
        //        NSLog(@"%@", [aPOI formattedDescription]);
        
        CloudPOIAnnotation *ann = [[CloudPOIAnnotation alloc] initWithCloudPOI:aPOI];
        [self.mapView addAnnotation:ann];
    }
    
    [self.mapView showAnnotations:self.mapView.annotations animated:YES];
}

- (void)gotoDetailForCloudPOI:(AMapCloudPOI *)cloudPOI
{
    if (cloudPOI != nil)
    {
        // cloudPOI 存在该气泡的信息
    }
}

#pragma mark - Cloud Search
// 以某一经纬度为中心点
- (void)searchCloudMapWithCenterLocationCoordinate2D:(CLLocationCoordinate2D )coordinate {
    
    NSString *tableID = (NSString *)TableID; // 云图的tableID
    
    AMapCloudPOIAroundSearchRequest *request = [[AMapCloudPOIAroundSearchRequest alloc] init];
    request.tableID = tableID;
    request.center = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    request.radius = 100000;
    request.offset = 100;  // 最多只能获取100条数据
    request.page = 1;  // 第一页
    
    [self.searchAPI AMapCloudPOIAroundSearch:request];
}


// 检索的类型
- (void)cloudPlaceIDSearch
{
    // 在当期城市内检索
    AMapCloudPOILocalSearchRequest *placeLocal = [[AMapCloudPOILocalSearchRequest alloc] init];
    [placeLocal setTableID:(NSString *)TableID];
    [placeLocal setCity:kCloudSearchCity];
    [placeLocal setKeywords:@""]; // 关键字
    [self.searchAPI AMapCloudPOILocalSearch:placeLocal];
}

#pragma mark - AMapSearchDelegate
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error
{
 
}

- (void)onCloudSearchDone:(AMapCloudSearchBaseRequest *)request response:(AMapCloudPOISearchResponse *)response
{
    [self addAnnotationsWithPOIs:[response POIs]];
}

#pragma mark - MAMapViewDelegate
// 可以使用自定义的大头针类型
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
            annotationView.image = [UIImage imageNamed:@"location_annotation"];
        }
        
        return annotationView;
    }
    return nil;
}

//- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
//{
//    if ([annotation isKindOfClass:[CloudPOIAnnotation class]])
//    {
//        static NSString *pointReuseIndetifier = @"PlaceIDSearchIndetifier";
//        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
//        if (annotationView == nil)
//        {
//            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
//        }
//        
//        annotationView.canShowCallout   = YES;
//        annotationView.animatesDrop     = NO;
//        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
//        
//        return annotationView;
//    }
//    
//    return nil;
//}

// 点击标注上对应的气泡
- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[CloudPOIAnnotation class]])
    {
        [self gotoDetailForCloudPOI:[(CloudPOIAnnotation *)view.annotation cloudPOI]];
    }
}

@end
