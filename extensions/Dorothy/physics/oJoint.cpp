/* Copyright (c) 2013 Jin Li, http://www.luv-fight.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#include "Dorothy/const/oDefine.h"
#include "Dorothy/physics/oJoint.h"
#include "Dorothy/physics/oBody.h"
#include "Dorothy/physics/oWorld.h"
#include "Dorothy/physics/oSensor.h"

NS_DOROTHY_BEGIN

oJoint::~oJoint()
{
	oJoint::destroy();
}

b2Joint* oJoint::getB2Joint()
{
	return _joint;
}

oWorld* oJoint::getWorld()
{
	return _world;
}

void oJoint::destroy()
{
	if (_world && _joint)
	{
		_world->getB2World()->DestroyJoint(_joint);
		_world = nullptr;
		_joint = nullptr;
	}
}

oJoint* oJoint::distance(
	oBody* bodyA, oBody* bodyB,
	const oVec2& anchorA, const oVec2& anchorB,
	float frequency, float damping)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 aA = oWorld::b2Val(anchorA);
	b2Vec2 aB = oWorld::b2Val(anchorB);
	b2DistanceJointDef jointDef;
	jointDef.Initialize(bA, bB,
		bA->GetWorldPoint(aA),
		bB->GetWorldPoint(aB));
	jointDef.frequencyHz = frequency;
	jointDef.dampingRatio = damping;
	oJoint* joint = new oJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oJoint* oJoint::friction(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& worldAnchor,
	float maxForce,
	float maxTorque)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 a = oWorld::b2Val(worldAnchor);
	b2FrictionJointDef jointDef;
	jointDef.Initialize(bA, bB, a);
	jointDef.maxForce = maxForce;
	jointDef.maxTorque = maxTorque;
	oJoint* joint = new oJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oJoint* oJoint::gear(
	oJoint* jointA,
	oJoint* jointB,
	float ratio)
{
	if (jointA->getWorld() != jointA->getWorld())
	{
		return nullptr;
	}
	b2GearJointDef jointDef;
	jointDef.joint1 = jointA->getB2Joint();
	jointDef.joint2 = jointB->getB2Joint();
	jointDef.ratio = ratio;
	oJoint* joint = new oJoint();
	joint->_world = jointA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oJoint* oJoint::spring(
	oBody* bodyA,
	oBody* bodyB,
	oVec2 linearOffset,
	float angularOffset,
	float maxForce,
	float maxTorque,
	float correctionFactor)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2MotorJointDef jointDef;
	jointDef.Initialize(bA, bB);
	jointDef.linearOffset = oWorld::b2Val(linearOffset);
	jointDef.angularOffset = -CC_DEGREES_TO_RADIANS(angularOffset);
	jointDef.maxForce = maxForce;
	jointDef.maxTorque = maxTorque;
	jointDef.correctionFactor = correctionFactor;
	oJoint* joint = new oJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oMoveJoint* oJoint::move(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& target,
	float maxForce,
	float frequency,
	float damping)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2MouseJointDef jointDef;
	jointDef.bodyA = bA;
	jointDef.bodyB = bB;
	jointDef.target = oWorld::b2Val(target);
	jointDef.maxForce = maxForce;
	jointDef.frequencyHz = frequency;
	jointDef.dampingRatio = damping;
	jointDef.collideConnected = true;
	oMoveJoint* joint = new oMoveJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oMotorJoint* oJoint::prismatic(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& worldAnchor,
	const oVec2& axis,
	float lowerTranslation,
	float upperTranslation,
	float maxMotorForce,
	float motorSpeed)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 a = oWorld::b2Val(worldAnchor);
	b2PrismaticJointDef jointDef;
	jointDef.Initialize(bA, bB, a, axis);
	jointDef.lowerTranslation = lowerTranslation;
	jointDef.upperTranslation = upperTranslation;
	jointDef.enableLimit = lowerTranslation || upperTranslation;
	jointDef.maxMotorForce = maxMotorForce;
	jointDef.motorSpeed = motorSpeed;
	oMotorJoint* joint = new oMotorJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oJoint* oJoint::pulley(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& anchorA,
	const oVec2& anchorB,
	const oVec2& groundAnchorA,
	const oVec2& groundAnchorB,
	float32 ratio)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 aA = oWorld::b2Val(anchorA);
	b2Vec2 aB = oWorld::b2Val(anchorB);
	b2Vec2 gA = oWorld::b2Val(groundAnchorA);
	b2Vec2 gB = oWorld::b2Val(groundAnchorB);
	b2PulleyJointDef jointDef;
	jointDef.Initialize(bA, bB, gA, gB, aA, aB, ratio);
	oJoint* joint = new oJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oMotorJoint* oJoint::revolute(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& worldPos,
	float lowerAngle,
	float upperAngle,
	float maxMotorTorque,
	float motorSpeed)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 a = oWorld::b2Val(worldPos);
	lowerAngle = -CC_DEGREES_TO_RADIANS(lowerAngle);
	upperAngle = -CC_DEGREES_TO_RADIANS(upperAngle);
	motorSpeed = -CC_DEGREES_TO_RADIANS(motorSpeed);
	b2RevoluteJointDef jointDef;
	jointDef.Initialize(bA, bB, a);
	jointDef.lowerAngle = lowerAngle;
	jointDef.upperAngle = upperAngle;
	jointDef.enableLimit = lowerAngle || upperAngle;
	jointDef.maxMotorTorque = maxMotorTorque;
	jointDef.motorSpeed = motorSpeed;
	oMotorJoint* joint = new oMotorJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oJoint* oJoint::rope(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& anchorA,
	const oVec2& anchorB,
	float maxLength)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 aA = oWorld::b2Val(anchorA);
	b2Vec2 aB = oWorld::b2Val(anchorB);
	b2RopeJointDef jointDef;
	jointDef.bodyA = bA;
	jointDef.bodyB = bB;
	jointDef.localAnchorA = aA;
	jointDef.localAnchorB = aB;
	jointDef.maxLength = oWorld::b2Val(maxLength);
	oJoint* joint = new oJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oJoint* oJoint::weld(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& worldPos,
	float frequency,
	float damping)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 a = oWorld::b2Val(worldPos);
	b2WeldJointDef jointDef;
	jointDef.Initialize(bA, bB, a);
	jointDef.frequencyHz = frequency;
	jointDef.dampingRatio = damping;
	oJoint* joint = new oJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

oMotorJoint* oJoint::wheel(
	oBody* bodyA,
	oBody* bodyB,
	const oVec2& worldPos,
	const oVec2& axis,
	float maxMotorTorque,
	float motorSpeed,
	float frequency,
	float damping)
{
	if (bodyA->getWorld() != bodyB->getWorld())
	{
		return nullptr;
	}
	b2Body* bA = bodyA->getB2Body();
	b2Body* bB = bodyB->getB2Body();
	b2Vec2 a = oWorld::b2Val(worldPos);
	b2WheelJointDef jointDef;
	jointDef.Initialize(bA, bB, a, axis);
	jointDef.maxMotorTorque = maxMotorTorque;
	jointDef.motorSpeed = oWorld::b2Val(motorSpeed);
	jointDef.frequencyHz = frequency;
	jointDef.dampingRatio = damping;
	oMotorJoint* joint = new oMotorJoint();
	joint->_world = bodyA->getWorld();
	joint->_joint = joint->_world->getB2World()->CreateJoint(&jointDef);
	joint->autorelease();
	return joint;
}

void oMoveJoint::setTarget(const oVec2& targetPos)
{
	_target = targetPos;
	b2MouseJoint* joint = (b2MouseJoint*)_joint;
	joint->SetTarget(oWorld::b2Val(targetPos));
}
const oVec2& oMoveJoint::getTarget() const
{
	return _target;
}

oMotorJoint::oMotorJoint():
_motorEnabled(false)
{ }

void oMotorJoint::setMotorEnabled(bool var)
{
	_motorEnabled = var;
	switch (_joint->GetType())
	{
	case e_prismaticJoint:
		((b2PrismaticJoint*)_joint)->EnableMotor(var);
		break;
	case e_revoluteJoint:
		((b2RevoluteJoint*)_joint)->EnableMotor(var);
		break;
	case e_wheelJoint:
		((b2WheelJoint*)_joint)->EnableMotor(var);
		break;
	}
}
bool oMotorJoint::isMotorEnabled() const
{
	return _motorEnabled;
}

NS_DOROTHY_END
