/**
 * refer to:
 *   @link http://codeanticode.wordpress.com/2012/03/26/opengl-in-processing-2-0-alpha-5/
 *   @link http://www.openprocessing.org/sketch/59608
 *   @link http://processing.org/learning/basics/trianglestrip.html
 *   @link http://processing.org/learning/library/geometry.html
 */
import java.lang.IllegalStateException;
import java.util.ArrayList;
import java.lang.Math;

// other constant variables;
static final String APP_NAME = "modoki6";
static final float ARRAY_LIST_GROWING_CAPACITY_RATE = 1.2;
static final float SINCOS_PRECISION=1.0;
static final int SINCOS_LENGTH= int((360.0/SINCOS_PRECISION));

// cosmos constant variables
static final float EARTH_SYSTEM_ROTATE_Y_PER_MILLIS = TWO_PI / 360 * 5 / 1000;

// satellite constant variables
static final int DEFAULT_SATELLITE_NUM = 8;

// packet line constant variables
static final int DEFAULT_PACKET_LINE_NUM = 200;
static final int ADD_PACKET_LINE_MILLIS = 100;
static final int REMOVE_PACKET_LINE_MILLIS = 250;

// variables
PShape cosmos;
Earth earth;
ArrayList satellites;
ArrayList packet_lines;

// system variables
static float sinLUT[];
static float cosLUT[];
int lastMillis;
int addPacketLineMillis;
int removePacketLineMillis;
int counter;

void setup() {
  size(640, 480, P3D);
  background(0);
  initSystem();
  initCosmos();
}

void draw() {
  background(0);
  int m = millis();

  // update satellite
  int satellite_num = satellites.size();
  for (int i = 0; i < satellite_num; ++i) {
    Satellite s = (Satellite)satellites.get(i);
    s.update(m);
    s.updateShape(m);
  }
  
  // add or remove packet line
  if (m - addPacketLineMillis >= ADD_PACKET_LINE_MILLIS) {
    int num = int((m - addPacketLineMillis) / ADD_PACKET_LINE_MILLIS);
    addPacketLineMillis = m + (m - addPacketLineMillis) % ADD_PACKET_LINE_MILLIS;
    for (int i = 0; i < num; i++) {
      addPacketLine();
    }
  }
  if (m - removePacketLineMillis >= REMOVE_PACKET_LINE_MILLIS) {
    int num = int((m - removePacketLineMillis) / REMOVE_PACKET_LINE_MILLIS);
    removePacketLineMillis = m + (m - removePacketLineMillis) % REMOVE_PACKET_LINE_MILLIS;
    for (int i = 0; i < num; i++) {
      removePacketLine();
    }
  }

  // update packet line
  int line_num = packet_lines.size();
  for (int i = 0; i < line_num; ++i) {
    PacketLine pl = (PacketLine)packet_lines.get(i);
    pl.update(m);
    pl.updateShape(m);
  }

  // update cosmos
  cosmos.rotateY(EARTH_SYSTEM_ROTATE_Y_PER_MILLIS * (m - lastMillis));

  // draw cosmos
  shape(cosmos);

  // set camera
  camera(mouseX, -mouseY, 220.0, // eyeX, eyeY, eyeZ
  0.0, 0.0, 0.0, // centerX, centerY, centerZ
  0.0, 1.0, 0.0); // upX, upY, upZ

  // update timer
  lastMillis = m;
  counter = 0;
}

void mousePressed() {
  if (mouseButton == LEFT) {
    removeAllPacketLine();
  } else if (mouseButton == RIGHT) {
    saveFrame(APP_NAME+"_####.png");
  }
}


void initSystem() {
  // Fill the tables
  sinLUT=new float[SINCOS_LENGTH];
  cosLUT=new float[SINCOS_LENGTH];
  for (int i = 0; i < SINCOS_LENGTH; i++) {
    sinLUT[i]= (float)Math.sin(i*DEG_TO_RAD*SINCOS_PRECISION);
    cosLUT[i]= (float)Math.cos(i*DEG_TO_RAD*SINCOS_PRECISION);
  }

  // set timer
  lastMillis = 0;
  addPacketLineMillis = 0;
  removePacketLineMillis = 0;
}

void initCosmos() {
  //set static values
  Satellite.setMaxNum(DEFAULT_SATELLITE_NUM);

  // create cosmos
  cosmos = createShape(PShape.GROUP);

  // create earth
  earth = new Earth();
  cosmos.addChild(earth.createShape(this));

  // create satellite
  satellites = new ArrayList(DEFAULT_SATELLITE_NUM);
  for (int i = 0; i < DEFAULT_SATELLITE_NUM; ++i) {
    Satellite s = new Satellite(i);
    cosmos.addChild(s.createShape(this));
    satellites.add(s);
  }

  // create default packet
  packet_lines = new ArrayList(DEFAULT_PACKET_LINE_NUM);
  for (int i = 0; i < DEFAULT_PACKET_LINE_NUM; ++i) {
    PacketLine pl = new PacketLine();
    cosmos.addChild(pl.createShape(this));
    cosmos.addChild(pl.createSecondaryShape(this));
    packet_lines.add(pl);
  }
}

void addPacketLine() {
  boolean isFound = false;
  int size = packet_lines.size();
  int no = (int)random(0, satellites.size());
  PacketLine pl;
  for (int i = 0; i < size; ++i) {
    pl = (PacketLine)packet_lines.get(i);
    if (pl.isNone()) {
      pl.startConnect(earth, (Connectable)satellites.get(no), millis());
      isFound = true;
      break;
    }
  }
  if (!isFound) {
    packet_lines.ensureCapacity((int)(size * ARRAY_LIST_GROWING_CAPACITY_RATE));
    int new_size = packet_lines.size();
    for (int i = size; i < new_size; ++i) {
      pl = new PacketLine();
      cosmos.addChild(pl.createShape(this));
      packet_lines.add(pl);
    }
  }
  counter++;
}

void removePacketLine() {
  int size = packet_lines.size();
  PacketLine pl;
  for (int i = 0; i < size; ++i) {
    pl = (PacketLine)packet_lines.get(i);
    if (pl.isConnected()) {
      pl.startDisconnect();
      counter--;
      break;
    }
  }
}

void removeAllPacketLine() {
  int size = packet_lines.size();
  PacketLine pl;
  for (int i = 0; i < size; ++i) {
    pl = (PacketLine)packet_lines.get(i);
    if (pl.isConnected()) {
      pl.startDisconnect();
    }
    counter--;
  }
}

static int safeAngle(int angle) {
  while (SINCOS_LENGTH<=angle) {
    angle-=SINCOS_LENGTH;
  }
  while (0>angle) {
    angle+=SINCOS_LENGTH;
  }
  return angle;
}

interface Connectable {
  public PVector getBasePoint();
  public PVector randomConnectPoint();
}

interface ShapeExportable {
  public PShape createShape(PApplet parent);
}

interface DynamicShapeContainer {
  public void updateShape(int millis);
}

static class Earth implements Connectable, ShapeExportable {
  // earth constant variables
  private static final int EARTH_RADIUS = 50;
  private static final int EARTH_DIAMETER = EARTH_RADIUS * 2;
  private static final int MAX_LONGITUDE_NUM = 30;
  private static final int MAX_LATITUDE_NUM = 10;
  private static final color EARTH_SURFACE_COLOR = 0xFF285DAF;

  // variables
  private PVector basePoint;

  public Earth() {
    this.basePoint = new PVector(0, 0, 0);
  }

  public PVector getBasePoint() {
    return basePoint;
  }
  
  public PVector randomConnectPoint() {
    PVector p = new PVector();
    p.x = (float)Math.random() * EARTH_DIAMETER - EARTH_RADIUS;
    p.y = (float)Math.random() * EARTH_DIAMETER - EARTH_RADIUS;
    p.z = (float)Math.sqrt(EARTH_RADIUS*EARTH_RADIUS-(p.x*p.x + p.y*p.y));
    return p;
  }

  public PShape createShape(PApplet parent) {
    PShape earth = parent.createShape(PShape.GROUP);
    earth.setName("earth");
    earth.enableStyle();
    PShape anEllipse;
    // longitude circle
    for (int i = 0; i < MAX_LONGITUDE_NUM; ++i) {
      anEllipse = parent.createShape(
      ELLIPSE, -EARTH_RADIUS, -EARTH_RADIUS, 
      EARTH_DIAMETER, EARTH_DIAMETER); // CORNER ?
      anEllipse.rotateY(TWO_PI/MAX_LONGITUDE_NUM*i);
      anEllipse.noFill();
      anEllipse.stroke(EARTH_SURFACE_COLOR);
      earth.addChild(anEllipse);
    }
    // latitude circle
    float anEllipse_h, anEllipse_r;
    for (int i = 0; i < MAX_LATITUDE_NUM; ++i) {
      if (i == 0 || i == MAX_LATITUDE_NUM - 10) continue;
      anEllipse_h = EARTH_RADIUS - EARTH_DIAMETER / MAX_LATITUDE_NUM * i;
      anEllipse_r = abs(sqrt(EARTH_RADIUS * EARTH_RADIUS - anEllipse_h * anEllipse_h));
      anEllipse = parent.createShape(
      ELLIPSE, -anEllipse_r, -anEllipse_r, 
      anEllipse_r * 2, anEllipse_r * 2); // CORNER ?
      anEllipse.rotateX(HALF_PI);
      anEllipse.translate(0, 0, anEllipse_h);
      anEllipse.noFill();
      anEllipse.stroke(EARTH_SURFACE_COLOR);
      earth.addChild(anEllipse);
    }
    return earth;
  }
}

static class Satellite implements Connectable, ShapeExportable, DynamicShapeContainer {
  // constant variables
  private static final int SATELLITE_DISTANCE = 150;
  private static final int SATELLITE_RING_WEIGHT = 10;
  private static final int SATELLITE_RADIUS_INNER = 24;
  private static final int SATELLITE_RADIUS_OUTER = 30;
  private static final int SATELLITE_RING_POINTS = 36;
  private static final int SATELLITE_DIAMETER = SATELLITE_RADIUS_OUTER * 2;
  private static final float RING_ROTATE_PER_MILLIS = TWO_PI / 3000;
  private static final int RING_ARC_DEGREE = 2;
  private static final color LIVENET_COLOR = 0xFF2E7CF3;
  private static final color DARKNET_COLOR = 0xFF0F1A76;

  // static variables
  private static int max_num = 0;

  // variables
  private PShape ring;
  private PVector basePoint;
  private int no;
  private int lastMillis;
  private PMatrix3D matrix;

  public Satellite(int no) {
    this.no = no;
    this.basePoint = calcBasePoint();
  }

  public static void setMaxNum(int num) {
    Satellite.max_num = num;
  }

  protected float calcBaseRadians() {
    return TWO_PI / max_num * no + HALF_PI;
  }

  protected PVector calcBasePoint() {
    float rad = calcBaseRadians() - HALF_PI;
    return new PVector(
    cos(rad) * SATELLITE_DISTANCE, 
    0, 
    -sin(rad) * SATELLITE_DISTANCE);
  }

  public PVector getBasePoint() {
    return basePoint;
  }
  
  public PVector randomConnectPoint() {
    PVector p = new PVector();
    int th = safeAngle(int(this.calcBaseRadians()/DEG_TO_RAD/SINCOS_PRECISION)); // rotate y-axis
    int a = safeAngle((int)(Math.random() * SINCOS_LENGTH)); // plot on the circle in xz-field
    p.x = this.basePoint.x + cosLUT[a] * SATELLITE_RADIUS_INNER * cosLUT[th];
    p.y = this.basePoint.y - sinLUT[a] * SATELLITE_RADIUS_INNER;
    p.z = this.basePoint.z - cosLUT[a] * SATELLITE_RADIUS_INNER * sinLUT[th];
    return p;
  }

  public PShape createShape(PApplet parent) {
    // draw as ring
    float px = 0, py = 0, pa = 0;
    PShape ring = parent.createShape(GROUP);
    parent.noiseSeed(this.no);
    for (int angle = 0; angle < SINCOS_LENGTH; ++angle) {
      ring.addChild(createRingArc(parent, angle, (parent.noise(angle/30.0) < 0.5 ? true : false))); // simulated IP space
    }
    ring.setName("satellite"+no);
    ring.rotateY(this.calcBaseRadians());
    ring.translate(0, 0, SATELLITE_DISTANCE);
    this.ring = ring;
    /*this.matrix = new PMatrix3D();
    this.matrix.rotateY(this.calcBaseRadians());
    this.matrix.translate(0, 0, SATELLITE_DISTANCE);*/
    return ring;
  }

  protected PShape createRingArc(PApplet parent, int base, boolean isLive) {
    int angle = int(min(RING_ARC_DEGREE/SINCOS_PRECISION, SINCOS_LENGTH-1));
    PShape arc = parent.createShape(QUAD_STRIP);
    arc.enableStyle();
    arc.fill(isLive ? LIVENET_COLOR : DARKNET_COLOR);
    arc.noStroke();
    for (int i = base; i < base + angle; ++i) {
      int a = safeAngle(i);
      arc.vertex(cosLUT[a]*SATELLITE_RADIUS_INNER, -sinLUT[a]*SATELLITE_RADIUS_INNER);
      arc.vertex(cosLUT[a]*SATELLITE_RADIUS_OUTER, -sinLUT[a]*SATELLITE_RADIUS_OUTER);
    }
    arc.end();
    return arc;
  }

  public void update(int millis) {
    int diffMillis = millis - this.lastMillis;
  }

  public void updateShape(int millis) {
    int diffMillis = millis - this.lastMillis;
    /*this.ring.resetMatrix();
    this.ring.rotateZ(RING_ROTATE_PER_MILLIS * diffMillis);
    this.ring.applyMatrix(
      this.matrix.m00, this.matrix.m01, this.matrix.m02, this.matrix.m03,
      this.matrix.m10, this.matrix.m11, this.matrix.m12, this.matrix.m13,
      this.matrix.m20, this.matrix.m21, this.matrix.m22, this.matrix.m23,
      this.matrix.m30, this.matrix.m31, this.matrix.m32, this.matrix.m33);*/
  }
}

static class PacketLine implements ShapeExportable, DynamicShapeContainer {
  // constant variables
  private static final int STATUS_NONE = 0;
  private static final int STATUS_CONNECTING = 1;
  private static final int STATUS_CONNECTED = 2;
  private static final int STATUS_DISCONNECTING = 3;
  private static final int STATUS_DISCONNECTED = 4;
  private static final float MAX_CONNECTING_PROGRESS = 100.0;
  private static final float INCREASE_CONNECTING_PROGRESS_PER_MILLIS = 0.005;
  private static final float DECREASE_DISCONNECTING_PROGRESS_PER_MILLIS = 0.005;
  private static final color LINE_COLOR = 0xC8739DEC;
  private static final float BALL_RADIUS = 0.8;
  private static final color BALL_COLOR = 0xC889B8D9;
  
  // variables
  private int lastMillis;
  private int status;
  private float progress;
  private PShape edge;
  private PShape ball;
  private PVector fromPoint;
  private PVector toPoint;

  public PacketLine() {
    this.status = STATUS_NONE;
  }

  public boolean isNone() {
    return this.status == STATUS_NONE;
  }

  public boolean isConnecting() {
    return this.status == STATUS_CONNECTING;
  }

  public boolean isConnected() {
    return this.status == STATUS_CONNECTED;
  }

  public boolean isDisconnecting() {
    return this.status == STATUS_DISCONNECTING;
  }

  public boolean isDisconnected() {
    return this.status == STATUS_DISCONNECTED;
  }

  public void startConnect(Connectable from, Connectable to, int millis) {
    this.fromPoint = from.randomConnectPoint();
    this.toPoint = to.randomConnectPoint();
    this.status = STATUS_CONNECTING;
    this.progress = 0;
    this.lastMillis = millis;
    this.ball.fill(BALL_COLOR);
  }

  public void startDisconnect() {
    this.status = STATUS_DISCONNECTING;
    this.progress = MAX_CONNECTING_PROGRESS;
  }

  public void update(int millis) {
    if (this.isNone()) return;
    if (this.isDisconnected()) return;
    if (this.isConnected()) return;
    int diffMillis = millis - this.lastMillis;
    if (this.isConnecting()) {
      this.progress += INCREASE_CONNECTING_PROGRESS_PER_MILLIS * diffMillis;
      if (this.progress >= MAX_CONNECTING_PROGRESS) {
        this.progress = MAX_CONNECTING_PROGRESS;
        this.status = STATUS_CONNECTED;
        this.updateLine();
      }
    } 
    else if (this.isDisconnecting()) {
      this.progress -= DECREASE_DISCONNECTING_PROGRESS_PER_MILLIS * diffMillis;
      if (this.progress <= 0) {
        this.progress = 0;
        this.status = STATUS_NONE; // STATUS_DISCONNECTED
        this.updateLine();
        this.ball.noFill();
      }
    }
  }

  public PShape createShape(PApplet parent) {
    // draw a line
    PShape edge = parent.createShape(LINES);
    edge.enableStyle();
    edge.noFill();
    //edge.noStroke();
    edge.stroke(LINE_COLOR);
    edge.vertex(0, 0);
    edge.vertex(0, 0);
    edge.end(CLOSE);
    this.edge = edge;
    return this.edge;
  }
  
  public PShape createSecondaryShape(PApplet parent) {
    PShape ball = parent.createShape(SPHERE, BALL_RADIUS);
    ball.enableStyle();
    ball.noFill();
    ball.noStroke();
    ball.end();
    this.ball = ball;
    return this.ball;
  }

  public void updateShape(int millis) {
    if (this.isConnecting() || this.isDisconnecting()) {
      this.updateLine();
    }
  }

  protected void updateLine() {
    if (this.edge.getVertexCount() != 2) {
      throw new IllegalStateException("invalid vertex count: "+this.edge.getVertexCount());
    }
    PVector p1 = this.edge.getVertex(0);
    PVector p2 = this.edge.getVertex(1);
    float amt = this.progress / MAX_CONNECTING_PROGRESS;
    if (this.isNone()) {
      p1.set(0, 0, 0);
      p2.set(0, 0, 0);
    } 
    else if (this.isConnecting()) {
      p1 = fromPoint;
      p2.x = lerp(fromPoint.x, toPoint.x, amt);
      p2.y = lerp(fromPoint.y, toPoint.y, amt);
      p2.z = lerp(fromPoint.z, toPoint.z, amt);
    } 
    else if (this.isConnected()) {
      p1 = fromPoint;
      p2 = toPoint;
    } 
    else if (this.isDisconnecting()) {
      p1.x = lerp(toPoint.x, fromPoint.x, amt);
      p1.y = lerp(toPoint.y, fromPoint.y, amt);
      p1.z = lerp(toPoint.z, fromPoint.z, amt);
      p2 = toPoint;
    } 
    else if (this.isDisconnected()) {
      p1.set(0, 0, 0);
      p2.set(0, 0, 0);
    }
    this.edge.setVertex(0, p1.x, p1.y, p1.z);
    this.edge.setVertex(1, p2.x, p2.y, p2.z);
    this.ball.resetMatrix();
    this.ball.translate(p2.x, p2.y, p2.z);
  }
}

