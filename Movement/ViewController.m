//
//  ViewController.m
//  Movement
//
//  Created by Robby Kraft on 11/1/13.
//  Copyright (c) 2013 Robby Kraft. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>

#define RECORD_LENGTH 3.0f

@interface ViewController () {

    GLfloat _fieldOfView;
    GLfloat _aspectRatio;
    BOOL _orientToDevice;
    CMMotionManager *motionManager;

    GLKMatrix4 _attitudeMatrix;
    GLKMatrix4 _attitudeVelocity;
    GLKMatrix4 _attitudeAcceleration;
    
    NSMutableArray *positionArray;
    NSMutableArray *velocityArray;
    NSMutableArray *accelerationArray;
    
    //recording
    GLfloat backgroundColor;
    BOOL recordMode;
    int recordIndex;
    NSTimer *recordTimer;
    int count;
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)initGL;
- (void)tearDownGL;
- (void)setOrientToDevice:(BOOL)orientToDevice;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1.0/45.0; // this will exhaust the battery!
    [self setOrientToDevice:YES];
   
    [self initGL];

    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.opaque = NO;  //why?
    
    backgroundColor = 0.0;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    backgroundColor = 1.0;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    backgroundColor = 0.0;
    if(![recordTimer isValid])
        [self beginRecording];
}

-(void)beginRecording{
    recordMode = YES;
    recordIndex = 0;
    positionArray = [NSMutableArray array];
    velocityArray = [NSMutableArray array];
    accelerationArray = [NSMutableArray array];
    recordTimer = [NSTimer scheduledTimerWithTimeInterval:RECORD_LENGTH target:self selector:@selector(endRecording) userInfo:Nil repeats:NO];
}

-(void)endRecording{
    recordMode = NO;
    NSLog(@"recordingDone");
    [recordTimer invalidate];
}

-(void)captureAttitudes{
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m00]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m01]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m02]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m10]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m11]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m12]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m20]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m21]];
    [positionArray addObject:[NSNumber numberWithFloat:_attitudeMatrix.m22]];

    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m00]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m01]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m02]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m10]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m11]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m12]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m20]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m21]];
    [velocityArray addObject:[NSNumber numberWithFloat:_attitudeVelocity.m22]];

    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m00]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m01]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m02]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m10]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m11]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m12]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m20]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m21]];
    [accelerationArray addObject:[NSNumber numberWithFloat:_attitudeAcceleration.m22]];
}

-(void)initGL{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:context];
    self.context = context;
    
    _fieldOfView = 75;
    _aspectRatio = (float)[[UIScreen mainScreen] bounds].size.width / (float)[[UIScreen mainScreen] bounds].size.height;
    if([UIApplication sharedApplication].statusBarOrientation > 2)
        _aspectRatio = 1/_aspectRatio;
    
    // init lighting
    glShadeModel(GL_SMOOTH);
    glLightModelf(GL_LIGHT_MODEL_TWO_SIDE,0.0);
    glEnable(GL_LIGHTING);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    float zNear = 0.01;
    float zFar = 1000;
    GLfloat frustum = zNear * tanf(GLKMathDegreesToRadians(_fieldOfView) / 2.0);
    glFrustumf(-frustum, frustum, -frustum/_aspectRatio, frustum/_aspectRatio, zNear, zFar);
    glViewport(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    glMatrixMode(GL_MODELVIEW);
    glEnable(GL_DEPTH_TEST);
    glLoadIdentity();
}

-(void)enterOrthographic{
    glDisable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrthof(0, [[UIScreen mainScreen] bounds].size.height, 0, [[UIScreen mainScreen] bounds].size.width, -5, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

-(void)exitOrthographic{
    glEnable(GL_DEPTH_TEST);
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}

-(void) setOrientToDevice:(BOOL)orientToDevice{
    _orientToDevice = orientToDevice;
    if(orientToDevice){
        if(motionManager.isDeviceMotionAvailable){
            [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler: ^(CMDeviceMotion *deviceMotion, NSError *error){
                    CMRotationMatrix a = deviceMotion.attitude.rotationMatrix;
                if(recordMode){
                    GLKMatrix4 aV =
                    GLKMatrix4Make(a.m11-_attitudeMatrix.m00, a.m21-_attitudeMatrix.m01, a.m31-_attitudeMatrix.m02, 0.0f,
                                   a.m13-_attitudeMatrix.m10, a.m23-_attitudeMatrix.m11, a.m33-_attitudeMatrix.m12, 0.0f,
                                   -a.m12-_attitudeMatrix.m20,-a.m22-_attitudeMatrix.m21,-a.m32-_attitudeMatrix.m22,0.0f,
                                   0.0f , 0.0f , 0.0f , 1.0f);
                    _attitudeAcceleration =
                    GLKMatrix4Make(aV.m00-_attitudeVelocity.m00, aV.m01-_attitudeVelocity.m01, aV.m02-_attitudeVelocity.m02, 0.0f,
                                   aV.m10-_attitudeVelocity.m10, aV.m11-_attitudeVelocity.m11, aV.m12-_attitudeVelocity.m12, 0.0f,
                                   aV.m20-_attitudeVelocity.m20, aV.m21-_attitudeVelocity.m21, aV.m22-_attitudeVelocity.m22, 0.0f,
                                   0.0f , 0.0f , 0.0f , 1.0f);
                    _attitudeVelocity = aV;
                    _attitudeMatrix =
                    GLKMatrix4Make(a.m11, a.m21, a.m31, 0.0f,
                                   a.m13, a.m23, a.m33, 0.0f,
                                   -a.m12,-a.m22,-a.m32,0.0f,
                                   0.0f , 0.0f , 0.0f , 1.0f);
                    if(count%20==0){
                        [self logOrientation];
                        [self captureAttitudes];
                    }
                }
                count++;
            }];
        }
    }
    else {
        [motionManager stopDeviceMotionUpdates];
    }
}

-(void)draw3DGraphs{
    static const GLfloat XAxis[] = {-1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f};
    static const GLfloat YAxis[] = {0.0f, -1.0f, 0.0f, 0.0f, 1.0f, 0.0f};
    static const GLfloat ZAxis[] = {0.0f, 0.0f, -1.0f, 0.0f, 0.0f, 1.0f};

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Set background color to black and opaque
    glClear(GL_COLOR_BUFFER_BIT);         // Clear the color buffer (background)
    
    glPushMatrix();
//    glMatrixMode(GL_MODELVIEW);
    
    GLfloat vertices[] = {-1, -1, 0, //bottom left corner
        -1,  1, 0, //top left corner
        1,  1, 0, //top right corner
        1, -1, 0}; // bottom right rocner
    
    GLubyte indices[] = {0,1,2, // first triangle (bottom left - top left - top right)
        0,2,3}; // second triangle (bottom left - top right - bottom right)

    glTranslatef(0.0, 0.0, -2.0);

    bool isInvertible;
    GLKMatrix4 inverse = GLKMatrix4Invert(_attitudeMatrix, &isInvertible);

    glRotatef(10.0, 1.0, 0.0, 0.0);
    glRotatef(count/5.0, 0.0, 1.0, 0.0);
    
//    glDisable(GL_TEXTURE_2D);
//    glDisable(GL_BLEND);
    glLineWidth(1.0);
//    glTranslatef([[UIScreen mainScreen] bounds].size.height*.5, [[UIScreen mainScreen] bounds].size.width*.5, 0.0);
//    glScalef(100/_aspectRatio, 100*_aspectRatio, 1);
//    glTranslatef(0.0, 0.0, 2.0);

//    glVertexPointer(3, GL_FLOAT, 0, vertices);
//    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);

    glColor4f(0.5, 0.5, 1.0, 1.0);
    glVertexPointer(3, GL_FLOAT, 0, XAxis);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDrawArrays(GL_LINE_LOOP, 0, 2);

    glVertexPointer(3, GL_FLOAT, 0, YAxis);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDrawArrays(GL_LINE_LOOP, 0, 2);
 
    glVertexPointer(3, GL_FLOAT, 0, ZAxis);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDrawArrays(GL_LINE_LOOP, 0, 2);

    glPopMatrix();

}

-(void)drawHexagons
{
    static const GLfloat hexVertices[] = {
        -.5f, -.8660254f, -1.0f, 0.0f, -.5f, .8660254f,
        .5f, .8660254f,    1.0f, 0.0f,  .5f, -.8660254f
    };
    
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_BLEND);
    glLineWidth(1.0);
    glTranslatef([[UIScreen mainScreen] bounds].size.height*.5, [[UIScreen mainScreen] bounds].size.width*.5, 0.0);
    glScalef(100/_aspectRatio, 100*_aspectRatio, 1);
    
    glColor4f(0.5, 0.5, 1.0, 1.0);
    glVertexPointer(2, GL_FLOAT, 0, hexVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glDrawArrays(GL_LINE_LOOP, 0, 6);
    
    glColor4f(0.5, 0.5, 1.0, 1.0);
    glScalef(1.175, 1.175, 1);
    glRotatef(-atan2f(_attitudeMatrix.m10, _attitudeMatrix.m11)*180/M_PI, 0, 0, 1);
    glDrawArrays(GL_LINE_LOOP, 0, 6);

    glLoadIdentity();
    glColor4f(0.5, 0.5, 1.0, 1.0);
    glTranslatef([[UIScreen mainScreen] bounds].size.height*.5, [[UIScreen mainScreen] bounds].size.width*.5, 0.0);
    glScalef(100/_aspectRatio/1.175, 100*_aspectRatio/1.175, 1);
    glRotatef(-atan2f(_attitudeMatrix.m00, _attitudeMatrix.m01)*180/M_PI, 0, 0, 1);
    glDrawArrays(GL_LINE_LOOP, 0, 6);

    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    
    glLoadIdentity();
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(backgroundColor, backgroundColor, backgroundColor, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    GLfloat white[] = {1.0,1.0,1.0,1.0};
    glMatrixMode(GL_MODELVIEW);
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, white);

    if(recordMode){
//        [self captureAttitudes];
        [self enterOrthographic];
        [self drawHexagons];
        [self exitOrthographic];
    }
    else{
        [self draw3DGraphs];
    }
}

-(void)logOrientation{
    NSLog(@"\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n+++++++++++++++++++++\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n#####################\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f\n%.3f, %.3f, %.3f",
          _attitudeMatrix.m00, _attitudeMatrix.m01, _attitudeMatrix.m02,
          _attitudeMatrix.m10, _attitudeMatrix.m11, _attitudeMatrix.m12,
          _attitudeMatrix.m20, _attitudeMatrix.m21, _attitudeMatrix.m22,
          _attitudeVelocity.m00, _attitudeVelocity.m01, _attitudeVelocity.m02,
          _attitudeVelocity.m10, _attitudeVelocity.m11, _attitudeVelocity.m12,
          _attitudeVelocity.m20, _attitudeVelocity.m21, _attitudeVelocity.m22,
          _attitudeAcceleration.m00, _attitudeAcceleration.m01, _attitudeAcceleration.m02,
          _attitudeAcceleration.m10, _attitudeAcceleration.m11, _attitudeAcceleration.m12,
          _attitudeAcceleration.m20, _attitudeAcceleration.m21, _attitudeAcceleration.m22);
}

- (void)tearDownGL{
    [EAGLContext setCurrentContext:self.context];
    //unload shapes
//    glDeleteBuffers(1, &_vertexBuffer);
//    glDeleteVertexArraysOES(1, &_vertexArray);
    self.effect = nil;
}

- (void)dealloc{
    [self tearDownGL];
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        [self tearDownGL];
        if ([EAGLContext currentContext] == self.context)
            [EAGLContext setCurrentContext:nil];
        
        self.context = nil;
    }
    // Dispose of any resources that can be recreated.
}

@end
