//
//  TextDectect.mm
//  Recognize text
//
//  Created by Lee Whitney on 10/28/14.
//  Copyright (c) 2014 WhitneyLand. All rights reserved.
//

#import  "TextDetect.h"
#include  "opencv2/text.hpp"
#include  "opencv2/highgui.hpp"
#include  "opencv2/imgproc.hpp"
#include  <vector>
#include  <iostream>
#include  <iomanip>
#import "ImageWrapper.h"
#import <UIKit/UIKit.h>
#include "opencv2/opencv.hpp"
#include "opencv2/highgui/highgui.hpp"

using namespace std;
using namespace cv;
using namespace cv::text;


struct Pnt{
    float x;
    float y;
};


struct Quadrilateral{
    Pnt topLeft;
    Pnt topRight;
    Pnt bottomLeft;
    Pnt bottomRight;
};

@implementation CImage

NSMutableArray *_channels;
Mat _image;
Mat _grouping;

vector<Mat> _vchannels;

-(id)initWithImage:(UIImage *)img {
    self = [super init];
    if(self){
        _channels = [[NSMutableArray alloc] init];
        
        NSData *data = [NSData dataWithData:UIImageJPEGRepresentation(img, 0.8f)];
        
        NSString *temp = NSTemporaryDirectory();
        NSString *guid = [[NSUUID new] UUIDString];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg",guid];
        NSString *localFilePath = [temp stringByAppendingPathComponent:fileName];
        [data writeToFile:localFilePath atomically:YES];
        
        
        _image = imread(localFilePath.UTF8String);
        
        Mat grey;
        cvtColor(_image,grey,COLOR_RGB2GRAY);
        _vchannels.clear();
        _vchannels.push_back(grey);
        _vchannels.push_back(255 - grey);
        
        for (int i = 0; i < 2; i++) {
            UIImage *img = MatToUIImage(_vchannels[i]);
            [_channels addObject:img];
        }
    }
    
    return self;
}

-(Mat)getImage {
    return _image;
}

-(vector<Mat>)getCVChannels {
    return _vchannels;
}

-(NSMutableArray *)channels {
    return _channels;
}

void UIImageToMat(const UIImage* image, cv::Mat& m,
                  bool alphaExist)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.
                                                      CGImage);
    CGFloat cols = image.size.width, rows = image.size.height;
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == 0)
    {
        m.create(rows, cols, CV_8UC1);
        //8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows,
                                           8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
            kCGBitmapByteOrderDefault;
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows,
                                           8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image.CGImage);
    CGContextRelease(contextRef);
}


UIImage* MatToUIImage(const cv::Mat& image)
{
    NSData *data = [NSData dataWithBytes:image.data length:image.
                    elemSize()*image.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(image.cols,   //width
                                        
                                        image.rows,   //height
                                        8,            //bits percomponent
                                        8*image.elemSize(),//bits
                                        
                                        image.step.p[0],   //
                                        
                                        colorSpace,   //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,//
                                        provider,     //
                                        //CGDataProviderRef
                                        NULL,         //decode
                                        false,        //should
                                        //interpolate
                                        kCGRenderingIntentDefault
                                        //intent
                                        );
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

/*-(UIImage*)getImage:(UIImage*)resizedImage {
    ImageWrapper *greyScale= Image::createImage(resizedImage, resizedImage.size.width, resizedImage.size.height);
    ImageWrapper *edges = greyScale.image->autoLocalThreshold();
    return edges.image->toUIImage();
}*/

-(UIImage*)getImage:(UIImage*)resizedImage {
    /*cv::Mat *m = new cv::Mat();
    UIImageToMat(resizedImage, *m, true);
    return MatToUIImage(*m);;*/
    cv::Point2f center(0,0);
    cv::Mat *oldsrc = new cv::Mat();
    UIImageToMat(resizedImage, *oldsrc, true);
    
    cv::Mat src = *oldsrc;
    
    cv::Mat bw;
    cv::cvtColor(src, bw, 6);
    cv::blur(bw, bw, cv::Size(3, 3));
    cv::Canny(bw, bw, 100, 100, 3);
    
    std::vector<cv::Vec4i> lines;
    cv::HoughLinesP(bw, lines, 1, CV_PI/180, 70, 30, 10);

    // Expand the lines
    for (int i = 0; i < lines.size(); i++)
    {
        cv::Vec4i v = lines[i];
        lines[i][0] = 0;
        lines[i][1] = ((float)v[1] - v[3]) / (v[0] - v[2]) * -v[0] + v[1];
        lines[i][2] = src.cols;
        lines[i][3] = ((float)v[1] - v[3]) / (v[0] - v[2]) * (src.cols - v[2]) + v[3];
    }
    
    std::vector<cv::Point2f> corners;
    for (int i = 0; i < lines.size(); i++)
    {
        for (int j = i+1; j < lines.size(); j++)
        {
            cv::Point2f pt = computeIntersect(lines[i], lines[j]);
            if (pt.x >= 0 && pt.y >= 0)
                corners.push_back(pt);
        }
    }
    
    std::vector<cv::Point2f> approx;
    cv::approxPolyDP(cv::Mat(corners), approx, cv::arcLength(cv::Mat(corners), true) * 0.02, true);
    
    if (approx.size() != 4)
    {
        //std::cout << "The object is not quadrilateral!" << std::endl;
    }
    
    // Get mass center
    for (int i = 0; i < corners.size(); i++)
        center += corners[i];
    center *= (1. / corners.size());
    
    sortCorners(corners, center);
    if (corners.size() == 0){
        //std::cout << "The corners were not sorted correctly!" << std::endl;
    }
    cv::Mat dst = src.clone();
    
    cv::Mat quad = cv::Mat::zeros(300, 220, CV_8UC3);
    
    std::vector<cv::Point2f> quad_pts;
    quad_pts.push_back(cv::Point2f(0, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, 0));
    quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
    quad_pts.push_back(cv::Point2f(0, quad.rows));
    
    cv::Mat transmtx = cv::getPerspectiveTransform(corners, quad_pts);
    cv::warpPerspective(src, quad, transmtx, quad.size());
    
    return MatToUIImage(quad);
}


cv::Point2f computeIntersect(cv::Vec4i a,
                             cv::Vec4i b)
{
    int x1 = a[0], y1 = a[1], x2 = a[2], y2 = a[3], x3 = b[0], y3 = b[1], x4 = b[2], y4 = b[3];
    if (float d = ((float)(x1 - x2) * (y3 - y4)) - ((y1 - y2) * (x3 - x4)))
    {
        cv::Point2f pt;
        pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
        pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
        return pt;
    }
    else
        return cv::Point2f(-1, -1);
}

void sortCorners(std::vector<cv::Point2f>& corners,
                 cv::Point2f center)
{
    std::vector<cv::Point2f> top, bot;
    
    for (int i = 0; i < corners.size(); i++)
    {
        if (corners[i].y < center.y)
            top.push_back(corners[i]);
        else
            bot.push_back(corners[i]);
    }
    corners.clear();
    
    if (top.size() == 2 && bot.size() == 2){
        cv::Point2f tl = top[0].x > top[1].x ? top[1] : top[0];
        cv::Point2f tr = top[0].x > top[1].x ? top[0] : top[1];
        cv::Point2f bl = bot[0].x > bot[1].x ? bot[1] : bot[0];
        cv::Point2f br = bot[0].x > bot[1].x ? bot[0] : bot[1];
        
        
        corners.push_back(tl);
        corners.push_back(tr);
        corners.push_back(br);
        corners.push_back(bl);
    }
}


@end

@implementation ExtremeRegionStat

vector<ERStat> _region;

-(id)initWithRegion: (vector<ERStat>)region {
    self = [super init];
    if(self) {
        _region = region;
    }
    return self;
}

-(vector<ERStat>)getRegion {
    return _region;
}

+(UIImage*)groupImage : (CImage*)image WithRegions: (NSArray *)regions{
    
    vector<vector<ERStat>> _regions;
    
    for(int i = 0; i< regions.count; i++){
        ExtremeRegionStat *stat = [regions objectAtIndex:i];
        _regions.push_back([stat getRegion]);
    }
    vector< vector<Vec2i> > nm_region_groups;
    vector<cv::Rect> nm_boxes;
    
    Mat cvImg = [image getImage];
    
    erGrouping(cvImg, [image getCVChannels] , _regions, nm_region_groups, nm_boxes,ERGROUPING_ORIENTATION_HORIZ);
    
    groups_draw(cvImg, nm_boxes);
    
    return MatToUIImage(cvImg);
}

void groups_draw(Mat &src, vector<cv::Rect> &groups)
{
    for (int i=(int)groups.size()-1; i>=0; i--)
    {
        if (src.type() == CV_8UC3)
            rectangle(src,groups.at(i).tl(),groups.at(i).br(),Scalar( 0, 255, 255 ), 3, 8 );
        else
            rectangle(src,groups.at(i).tl(),groups.at(i).br(),Scalar( 255 ), 3, 8 );
    }
}

@end

@interface ExtremeRegionFilter ()

@property (nonatomic) Ptr<ERFilter> filter;

@end

@implementation ExtremeRegionFilter

-(id) init {
    self = [super init];
    if(self){
        
    }
    return self;
}

-(ExtremeRegionStat*)run : (UIImage*)img{
    vector<ERStat> region;
   
    Mat cMat;
    UIImageToMat(img, cMat, false);
    
    _filter->run(cMat, region);
    ExtremeRegionStat * stat = [[ExtremeRegionStat alloc] initWithRegion:region];
    return stat;
}

+ (ExtremeRegionFilter *)createERFilterNM1:(NSString *)classifierPath c:(float)c x:(float)x y:(float)y f:(float)f a:(bool)a scale:(float)scale {
    
    const char *classifier1utf = classifierPath.UTF8String;
    
    Ptr<ERFilter> filter = createERFilterNM1(loadClassifierNM1(classifier1utf),c, x , y, f, a, scale);
    
    ExtremeRegionFilter *erFilter = [[ExtremeRegionFilter alloc] init];
    [erFilter setFilter:filter];
    
    return erFilter;
}

+ (ExtremeRegionFilter *)createERFilterNM2:(NSString *)classifier andX:(float)x {
    
    const char *classifier2utf = classifier.UTF8String;
    
    Ptr<ERFilter> filter = createERFilterNM2(loadClassifierNM1(classifier2utf),x);
    
    ExtremeRegionFilter *erFilter = [[ExtremeRegionFilter alloc] init];
    [erFilter setFilter:filter];
    
    return erFilter;
}

+ (CIImage *)filteredImageUsingEnhanceFilterOnImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, image, @"inputBrightness", [NSNumber numberWithFloat:0.0], @"inputContrast", [NSNumber numberWithFloat:1.14], @"inputSaturation", [NSNumber numberWithFloat:0.0], nil].outputImage;
}

+ (CIImage *)filteredImageUsingContrastFilterOnImage:(CIImage *)image
{
    return [CIFilter filterWithName:@"CIColorControls" withInputParameters:@{@"inputContrast":@(1.1),kCIInputImageKey:image}].outputImage;
}

+ (CIImage *)correctPerspectiveForImage:(CIImage *)image withFeatures:(CIRectangleFeature *)rectangleFeature
{
    NSMutableDictionary *rectangleCoordinates = [NSMutableDictionary new];
    rectangleCoordinates[@"inputTopLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.topLeft];
    rectangleCoordinates[@"inputTopRight"] = [CIVector vectorWithCGPoint:rectangleFeature.topRight];
    rectangleCoordinates[@"inputBottomLeft"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomLeft];
    rectangleCoordinates[@"inputBottomRight"] = [CIVector vectorWithCGPoint:rectangleFeature.bottomRight];
    return [image imageByApplyingFilter:@"CIPerspectiveCorrection" withInputParameters:rectangleCoordinates];
}


@end


