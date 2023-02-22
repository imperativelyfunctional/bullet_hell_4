import 'dart:math';

import 'package:bullet_hell/bullets.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Bullet extends SpriteAnimationComponent with HasGameRef, BulletsMixin {
  final double? movingDirection;
  double speed;
  final bool moveLongAngle;
  final bool increaseSpeed;
  final bool randomizeStepTime;
  late int bornTime;
  double speedIncrement;

  Bullet(this.movingDirection,
      {this.speed = 100,
      this.moveLongAngle = true,
      this.increaseSpeed = false,
      this.randomizeStepTime = false,
      this.speedIncrement = 10})
      : super() {
    super.angle = movingDirection!;
    bornTime = DateTime.now().millisecondsSinceEpoch;
    if (moveLongAngle && movingDirection == null) {
      throw Error();
    }
  }

  @override
  Future<void>? onLoad() async {
    anchor = Anchor.center;
    animation = await gameRef.loadSpriteAnimation(
        'bb.png',
        SpriteAnimationData.sequenced(
            texturePosition: Vector2.zero(),
            amount: 5,
            stepTime: Random().nextDouble() * 1,
            textureSize: Vector2(60, 60),
            loop: true));
    size = Vector2(60, 60);
    add(RectangleHitbox(position: Vector2.zero(), size: size));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (moveLongAngle) {
      if (increaseSpeed) {
        speed += speedIncrement;
      }
      moveWithAngle(movingDirection!, speed * dt);
    }
    if (DateTime.now().millisecondsSinceEpoch - bornTime > 10000) {
      removeFromParent();
    }
    super.update(dt);
  }
}
