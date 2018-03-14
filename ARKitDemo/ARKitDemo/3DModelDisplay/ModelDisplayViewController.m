//
//  ModelDisplayViewController.m
//  3DModel
//
//  Created by 朱慧平 on 2017/11/27.
//  Copyright © 2017年 shinetechchina. All rights reserved.
//

#import "ModelDisplayViewController.h"
#import <ARKit/ARKit.h>
#import <SceneKit/SceneKit.h>

typedef enum : NSUInteger {
    CollisionCategoryPlan,
    CollisionCategoryModel
} CollisionCategory;


@interface ModelDisplayViewController ()<ARSCNViewDelegate,SCNPhysicsContactDelegate,UIGestureRecognizerDelegate> {
    
}
@property (nonatomic,strong)ARSCNView *sceneView;
@property (nonatomic,strong)SCNNode *modelNode;
@property (nonatomic,strong)SCNNode *selectedNode;
@property (nonatomic,strong)UIButton *backButton;
@property (nonatomic,strong)UIButton *rotateButton;

@end

@implementation ModelDisplayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self addSceneView];
    [self addUIView];
    [self addGestureRecognizer];
    [self addModelInSceneView];
}
- (void)addModelInSceneView{
    [self loadModel:SCNVector3Make(0, -0.3, -0.5)];
}
- (void)loadModel:(SCNVector3)pos{
    if (!_modelNode) {
        switch (_modelType) {
            case ModelTypeWolf:{
                SCNScene *scene = (SCNScene *)[SCNScene sceneNamed:@"wolf.scnassets/wolf.DAE"];
                _modelNode = [scene.rootNode childNodeWithName:@"wolf" recursively:YES];
                SCNParticleSystem *particles = [SCNParticleSystem particleSystemNamed:@"Snow" inDirectory:nil];
                if (particles) {
                    [_modelNode addParticleSystem:particles];
                }
            }
                break;
            case ModelTypeProductLine:{
                SCNScene *scene = (SCNScene *)[SCNScene sceneNamed:@"productLine.scnassets/productLine.DAE"];
                _modelNode = [scene.rootNode childNodeWithName:@"line" recursively:YES];
                _modelNode.scale = SCNVector3Make(0.001, 0.001, 0.001);
            }
                break;
            default:
                break;
        }
        _modelNode.position = pos;
        [_sceneView.scene.rootNode addChildNode:_modelNode];
    }
}
- (void)addSceneView{
    _sceneView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_sceneView];
    [_sceneView setUserInteractionEnabled:YES];
    _sceneView.delegate = self;
    _sceneView.showsStatistics = YES;
    _sceneView.automaticallyUpdatesLighting = YES;
    _sceneView.scene = [[SCNScene alloc] init];
    _sceneView.scene.physicsWorld.contactDelegate = self;
    ARWorldTrackingConfiguration *configuration = [[ARWorldTrackingConfiguration alloc] init];
    [configuration setPlaneDetection:ARPlaneDetectionHorizontal];
    [configuration setLightEstimationEnabled:YES];
    [_sceneView.session runWithConfiguration:configuration];
}
- (void)addUIView{
    _backButton = [[UIButton alloc] init];
    [_backButton setImageEdgeInsets:UIEdgeInsetsMake(0, 20, 0, 48)];
    [_backButton setImage:[UIImage imageNamed:@"leftArrow"] forState:UIControlStateNormal];
    
    _backButton.frame = CGRectMake(0, 20, 80, 40);
    [_backButton addTarget:self action:@selector(backButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backButton];
    _rotateButton = [[UIButton alloc] init];
    [_rotateButton setTitle:@"Rotate" forState:UIControlStateNormal];
    [_rotateButton setTitle:@"Stop" forState:UIControlStateSelected];
    [_rotateButton setSelected:NO];
    _rotateButton.frame = CGRectMake(self.view.frame.size.width - 80, 20, 80, 40);
    [_rotateButton addTarget:self action:@selector(rotateButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_rotateButton];
}
- (void)addGestureRecognizer{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    pan.maximumNumberOfTouches = 1;
    pan.minimumNumberOfTouches = 1;
    [self.sceneView addGestureRecognizer:pan];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognizer:)];
    [self.sceneView addGestureRecognizer:pinch];
}
- (void)backButtonClick:(UIButton *)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)rotateButtonClick:(UIButton *)sender{
    if (_modelNode) {
        [_rotateButton setSelected:!_rotateButton.isSelected];
        if (_rotateButton.isSelected) {
            [_modelNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2 z:0 duration:1]] forKey:@"rotate"];
        }else{
            [_modelNode removeActionForKey:@"rotate"];
        }
    }
}
- (void)panGestureRecognizer:(UIPanGestureRecognizer *)pan{
    if (pan.state == UIGestureRecognizerStateBegan) {
        _selectedNode = _modelNode;
    }else if (pan.state == UIGestureRecognizerStateChanged){
        if (_selectedNode) {
            CGPoint point = [pan locationInView:_sceneView];
            NSArray *hitResults =  [_sceneView hitTest:point types:ARHitTestResultTypeFeaturePoint];
            ARHitTestResult *result = [hitResults lastObject];
            SCNMatrix4 matrix = SCNMatrix4FromMat4(result.worldTransform);
            SCNVector3 vector = SCNVector3Make(matrix.m41, matrix.m42, matrix.m43);
            _selectedNode.position = vector;
            
        }
    }else if (pan.state == UIGestureRecognizerStateEnded){
        CGPoint point = [pan locationInView:_sceneView];
        NSArray *hitResults =  [_sceneView hitTest:point types:ARHitTestResultTypeExistingPlane];
        if (hitResults.count != 0) {
            ARHitTestResult *result = [hitResults lastObject];
            if (result.anchor != nil) {
                ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)result.anchor;
                if (planeAnchor) {
                  SCNNode *planeNode = [self createARPlaneNode:planeAnchor];
                    planeNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeKinematic shape:nil];
                    planeNode.physicsBody.categoryBitMask = CollisionCategoryPlan;
                    planeNode.physicsBody.contactTestBitMask = CollisionCategoryModel;
                    _selectedNode.physicsBody = [SCNPhysicsBody bodyWithType:SCNPhysicsBodyTypeDynamic shape:nil];
                    _selectedNode.physicsBody.mass = 0;
                    _selectedNode.physicsBody.categoryBitMask = CollisionCategoryModel;
                    _selectedNode.physicsBody.contactTestBitMask = CollisionCategoryPlan;
                    
                    SCNMatrix4 matrix = SCNMatrix4FromMat4(result.worldTransform);
                    SCNVector3 vector = SCNVector3Make(matrix.m41, matrix.m42, matrix.m43);
                    _selectedNode.position = vector;
                }
            }
            _selectedNode = nil;
        }
    }
    
}
- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer *)pinch{
    if (pinch.state == UIGestureRecognizerStateBegan) {
        _selectedNode = _modelNode;
    }else if (pinch.state == UIGestureRecognizerStateChanged){
        if (_selectedNode != nil) {
            float pinchScaleX = pinch.scale*_modelNode.scale.x;
            float pinchScaleY = pinch.scale*_modelNode.scale.y;
            float pinchScaleZ = pinch.scale*_modelNode.scale.z;
            _selectedNode.scale = SCNVector3Make(pinchScaleX, pinchScaleY, pinchScaleZ);
        }
        pinch.scale = 1;
    }else if (pinch.state == UIGestureRecognizerStateEnded){
        _selectedNode = nil;
    }
}
- (void)physicsWorld:(SCNPhysicsWorld *)world didUpdateContact:(SCNPhysicsContact *)contact{
    SCNNode *nodeA = contact.nodeA;
    SCNNode *nodeB = contact.nodeB;
    if (nodeA.physicsBody.categoryBitMask == CollisionCategoryModel) {
        nodeA.position = contact.contactPoint;
    }else{
        nodeB.position = contact.contactPoint;
    }
}
- (SCNNode *)createARPlaneNode:(ARPlaneAnchor *)anchor{
    SCNVector3 pos = SCNVector3Make(anchor.transform.columns[3].x, anchor.transform.columns[3].y, anchor.transform.columns[3].z);
    SCNPlane *plane = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
    UIImage *image = [UIImage imageNamed:@"grid"];
    SCNMaterial *floorMaterial = [[SCNMaterial alloc] init];
    floorMaterial.diffuse.contents = image;
    [floorMaterial setDoubleSided:YES];
    plane.materials = @[floorMaterial];
    SCNNode *planeNode = [SCNNode nodeWithGeometry:plane];
    planeNode.position = pos;
    planeNode.transform = SCNMatrix4MakeRotation(M_PI/2, 1, 0, 0);
    return planeNode;
}
- (void)renderer:(id<SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
    if (planeAnchor) {
        SCNNode *planeNode = [self createARPlaneNode:planeAnchor];
        [node addChildNode:planeNode];
    }
}
- (void)renderer:(id<SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
     ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
    for (SCNNode *childNode in node.childNodes) {
        [childNode removeFromParentNode];
    }
    SCNNode *planeNode = [self createARPlaneNode:planeAnchor];
    [node addChildNode:planeNode];
}
- (void)renderer:(id<SCNSceneRenderer>)renderer didRemoveNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor{
    ARPlaneAnchor *planeAnchor = (ARPlaneAnchor *)anchor;
    for (SCNNode *childNode in node.childNodes) {
        [childNode removeFromParentNode];
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
