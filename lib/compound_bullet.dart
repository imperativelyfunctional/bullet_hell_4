import 'dart:async';
import 'dart:math';

import 'package:bullet_hell/bullet.dart';
import 'package:flame/components.dart';

abstract class CompoundBullet extends PositionComponent {
  final Component parentSystem;
  final DateTime born = DateTime.now();

  CompoundBullet(
      {required super.position,
      required super.size,
      required this.parentSystem});

  @override
  FutureOr<void> onLoad() {
    super.onLoad();
    addChildren();
  }

  void addChildren();

  @override
  void update(double dt) {
    super.update(dt);
    if (DateTime.now().second - born.second >= 10) {
      removeFromParent();
    }
  }
}

class CircleCompoundBullet extends CompoundBullet {
  final double radius;

  final int numberOfChildren;

  final double speed;

  CircleCompoundBullet(
      {required super.position,
      required super.size,
      required super.parentSystem,
      required this.radius,
      required this.numberOfChildren,
      this.speed = 300});

  @override
  void addChildren() {
    double initialAngle = 0;
    double angleBetweenTwoChildren = 2 * pi / numberOfChildren;
    for (int i = 0; i < numberOfChildren; i++) {
      parentSystem.add(Bullet(
        increaseSpeed: true,
        speed: speed,
        initialAngle,
      )
        ..position =
            position + Vector2(cos(initialAngle), sin(initialAngle)) * radius
        ..scale = Vector2(0.5, 0.5));
      initialAngle += angleBetweenTwoChildren;
    }
  }
}

class RectangleCompoundBullet extends CompoundBullet {
  final Vector2 rectangleSize;

  final int numberOfChildrenInRow;
  final int numberOfChildrenInColumn;

  final double speed;

  RectangleCompoundBullet({
    required super.position,
    required super.size,
    required super.parentSystem,
    required this.rectangleSize,
    required this.numberOfChildrenInRow,
    required this.numberOfChildrenInColumn,
    this.speed = 500,
  });

  @override
  void addChildren() {
    var vector = rectangleSize / 2;
    var horizontalSpace = rectangleSize.x / (numberOfChildrenInRow - 1);
    var verticalSpace = rectangleSize.y / (numberOfChildrenInColumn - 1);
    var currentPosition = position - vector;
    int counter = 0;
    while (counter < numberOfChildrenInRow) {
      var angle = currentPosition.angleTo(position);
      parentSystem.add(Bullet(
        speed: speed,
        angle,
      )
        ..position = currentPosition
        ..scale = Vector2(0.5, 0.5));
      if (counter != numberOfChildrenInRow - 1) {
        currentPosition.x += horizontalSpace;
      }
      counter++;
    }
    counter = 0;
    while (counter < numberOfChildrenInColumn - 1) {
      currentPosition.y += verticalSpace;
      var angle = currentPosition.angleTo(position);
      parentSystem.add(Bullet(
        speed: speed,
        angle,
      )
        ..position = currentPosition
        ..scale = Vector2(0.5, 0.5));
      counter++;
    }
    counter = 0;
    while (counter < numberOfChildrenInRow - 1) {
      var angle = currentPosition.angleTo(position);
      parentSystem.add(Bullet(
        speed: speed,
        angle,
      )
        ..position = currentPosition
        ..scale = Vector2(0.5, 0.5));
      currentPosition.x -= horizontalSpace;
      counter++;
    }
    counter = 0;
    while (counter < numberOfChildrenInColumn - 1) {
      var angle = currentPosition.angleTo(position);
      parentSystem.add(Bullet(
        speed: 500,
        angle,
      )
        ..position = currentPosition
        ..scale = Vector2(0.5, 0.5));
      currentPosition.y -= verticalSpace;
      counter++;
    }
  }
}
