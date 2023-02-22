import 'dart:async' as async;
import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:bullet_hell/bullet_base.dart';
import 'package:bullet_hell/game_wall.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

import 'compound_bullet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  var bulletHell = BulletHell();
  runApp(GameWidget(game: bulletHell));
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1920, 1080);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Bullet Hell with Flutter";
    win.show();
  });
}

late Vector2 viewPortSize;

class BulletHell extends FlameGame with HasCollisionDetection {
  double radius = 100;
  late SpriteAnimationComponent boss;
  late MainEventHandler mainEventHandler;
  late GameWall gameWall;
  async.Timer? bossTimer;
  List<List<BulletBase>> bases = [];
  final List<Color> colors = [
    Colors.amber,
    Colors.tealAccent,
    Colors.green,
    Colors.lightGreenAccent,
    Colors.red,
    Colors.lime,
    Colors.indigo,
    Colors.white70,
    Colors.white10,
  ];

  @override
  Future<void> onLoad() async {
    super.onLoad();
    var viewDimension = Vector2(1920, 1080);
    viewPortSize = viewDimension;
    camera.viewport = FixedResolutionViewport(viewDimension);

    gameWall = GameWall();
    add(gameWall);

    add(SpriteComponent(
      sprite: await Sprite.load("background.png"),
    ));
    add(SpriteComponent(
      sprite: await Sprite.load("poem.png"),
    )
      ..opacity = 0
      ..add(OpacityEffect.to(0.4, SineEffectController(period: 60))));
    await addParallaxBackground();
    var boss = await addBoss();
    mainEventHandler = MainEventHandler(this, boss);
  }

  Future<SpriteAnimationComponent> addBoss() async {
    var imageSize = Vector2(101, 64);
    final running = await loadSpriteAnimation(
      'boss.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: imageSize,
        stepTime: 0.5,
      ),
    );

    boss = SpriteAnimationComponent(
        priority: 1,
        animation: running,
        anchor: Anchor.center,
        size: imageSize,
        angle: pi,
        position: Vector2(size.x / 2.0, -10),
        scale: Vector2(0.5, 0.5));
    boss.add(SequenceEffect(
      [
        MoveEffect.to(
            Vector2(size.x / 2.0, 800),
            EffectController(
                duration: 1, infinite: false, curve: Curves.bounceIn)),
        MoveEffect.to(
            Vector2(size.x / 2.0, 500),
            EffectController(
                duration: 1, infinite: false, curve: Curves.easeInExpo))
      ],
    ));
    add(boss);
    init(boss);
    return boss;
  }

  void init(SpriteAnimationComponent boss) {
    async.Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      bases
          .add(_layBases(boss.position, 0, 8, 100, color: Colors.yellowAccent));
      bases.add(_layBases(
        boss.position,
        0,
        8,
        120,
      ));
      bases.add(_layBases(boss.position, 0, 8, 140, color: Colors.pink));
      bases.add(
          _layBases(boss.position, 0, 8, 160, color: Colors.lightBlueAccent));
      bases.add(_layBases(boss.position, 0, 8, 180, color: Colors.lightGreen));
      bases.add(
          _layBases(boss.position, 0, 8, 180, color: Colors.deepPurpleAccent));
      timer.cancel();
    });

    int frequency = 400;
    List<async.Timer> timers = [];
    int counter = 0;
    async.Timer.periodic(const Duration(seconds: 1), (timer) {
      cleanTimers(timers);
      timers.addAll(moveBulletBases(bases, boss, frequency: frequency));
      frequency -= 40;
      counter++;
      if (counter > 10) {
        mainEventHandler.handleEvent("two");
        timer.cancel();
      }
    });
  }

  void _commonShootingProcedure(
      SpriteAnimationComponent boss, int periodInMilliseconds, Function shoot,
      {required String next}) {
    bool done = false;
    int frequency = 100;
    var numberOfRounds = periodInMilliseconds ~/ frequency;
    int round = 0;
    var shootingTimer =
        async.Timer.periodic(Duration(milliseconds: frequency), (timer) {
      if (!done) {
        round++;
        shoot();
        if (round >= numberOfRounds) {
          done = true;
          round = 0;
        }
      }
    });
    int coolDown = 0;
    int coolDownTimes = 0;
    async.Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (done) {
        coolDown++;
      }
      if (coolDown >= 20) {
        coolDown = 0;
        done = false;
        coolDownTimes++;
      }
      if (coolDownTimes >= 7) {
        shootingTimer.cancel();
        mainEventHandler.handleEvent(next);
        timer.cancel();
      }
    });
  }

  void cleanTimers(List<async.Timer> timers) {
    for (var element in timers) {
      element.cancel();
    }
    timers.clear();
  }

  List<async.Timer> moveBulletBases(
      List<List<BulletBase>> bases, SpriteAnimationComponent boss,
      {int frequency = 400}) {
    double radius = 100;
    int counter = 0;
    List<async.Timer> timers = [];
    for (var element in bases) {
      for (var element in element) {
        timers.add(element.moveAround(boss.position, radius,
            ((counter % 2 == 1) ? -1 : 1) * pi / 8, frequency));
      }
      counter++;
      radius += 20;
    }
    return timers;
  }

  List<BulletBase> _layBases(
    Vector2 reference,
    double initialAngle,
    int numberOfBases,
    double radius, {
    Color color = Colors.white,
  }) {
    List<BulletBase> bases = [];
    double angleBetweenBases = 2 * pi / numberOfBases;
    for (int i = 0; i < numberOfBases; i++) {
      var angle = initialAngle + i * angleBetweenBases;
      var base = BulletBase(color,
          radius: 5,
          position: reference + Vector2(cos(angle), sin(angle)) * radius,
          autoRemove: false);
      bases.add(base);
      add(base);
    }
    return bases;
  }

  Future<void> addParallaxBackground() async {
    final layerInfo = {
      'background_1.png': 6.0,
      'background_2.png': 8.5,
      'background_3.png': 12.0,
      'background_4.png': 20.5,
    };

    final parallax = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(layerInfo.entries.map(
          (entry) => loadParallaxLayer(
            ParallaxImageData(entry.key),
            fill: LayerFill.width,
            repeat: ImageRepeat.repeat,
            velocityMultiplier: Vector2(entry.value, entry.value),
          ),
        )),
        baseVelocity: Vector2(10, 10),
      ),
    );

    Random().nextBool() ? ImageRepeat.repeatX : ImageRepeat.repeatY;
    async.Timer.periodic(const Duration(seconds: 2), (timer) {
      parallax.parallax?.baseVelocity = Vector2(
        Random().nextBool()
            ? Random().nextInt(20).toDouble()
            : -Random().nextInt(20).toDouble(),
        Random().nextBool()
            ? -Random().nextInt(20).toDouble()
            : -Random().nextInt(20).toDouble(),
      );
    });
    add(parallax);
  }

  void patternOne({timesToRun = 2}) {
    int round = 0;
    async.Timer.periodic(const Duration(milliseconds: 200), (timer) {
      round++;
      double initialAngle = 0;
      int numberOfSpawnPoints = 15;
      var other = (2 * pi / numberOfSpawnPoints);
      radius -= 20;
      for (int i = 0; i < numberOfSpawnPoints; i++) {
        var angle = initialAngle + i * other;
        add(CircleCompoundBullet(
            position: boss.position + Vector2(cos(angle), sin(angle)) * radius,
            size: Vector2.zero(),
            parentSystem: this,
            radius: 50,
            numberOfChildren: 10)
          ..anchor = Anchor.center);
      }
      if (round >= timesToRun) {
        timer.cancel();
      }
    });
  }

  void patternTwo() {
    int round = 0;
    double radius = 20;
    int numberOfSpawnPoints = 10;
    double speed = 200;
    async.Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      round++;
      double initialAngle = 0;
      var other = (2 * pi / numberOfSpawnPoints);
      for (int i = 0; i < numberOfSpawnPoints; i++) {
        var angle = initialAngle + i * other;
        add(CircleCompoundBullet(
            position: boss.position +
                Vector2(cos(angle), sin(angle)) * (100 + radius),
            size: Vector2.zero(),
            parentSystem: this,
            radius: radius,
            speed: speed,
            numberOfChildren: 12)
          ..anchor = Anchor.center);
      }
      if (round >= 10) {
        mainEventHandler.handleEvent("one");
        timer.cancel();
      }
      radius += 20;
      numberOfSpawnPoints += 2;
      speed += 30;
    });
  }
}

abstract class EventHandler {
  void handleEvent(String event);
}

class MainEventHandler extends EventHandler {
  final BulletHell bulletHell;
  final SpriteAnimationComponent boss;

  MainEventHandler(this.bulletHell, this.boss);

  @override
  void handleEvent(String event) {
    switch (event) {
      case "one":
        {
          bulletHell.radius = 100;
          bulletHell._commonShootingProcedure(
              next: "two", boss, 300, () => bulletHell.patternOne());
          break;
        }
      case "two":
        {
          bulletHell.patternTwo();
          break;
        }
    }
  }
}
