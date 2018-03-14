//
//  ModelDisplayViewController.h
//  3DModel
//
//  Created by 朱慧平 on 2017/11/27.
//  Copyright © 2017年 shinetechchina. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum : NSUInteger{
    ModelTypeWolf = 0,
    ModelTypeProductLine = 1
}ModelType;
@interface ModelDisplayViewController : UIViewController
@property (nonatomic,assign)ModelType modelType;
@end
