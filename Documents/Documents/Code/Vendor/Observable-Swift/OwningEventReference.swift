//
//  OwningEventReference.swift
//  Observable-Swift
//
//  Created by Leszek Ślażyński on 28/06/14.
//  Copyright (c) 2014 Leszek Ślażyński. All rights reserved.
//

/// A subclass of event reference allowing it to own other object[s].
/// Additionally, the reference makes added events own itself.
/// This retain cycle allows owned objects to live as long as valid subscriptions exist.
public class OwningEventReference<T>: EventReference<T> {
    internal var owned: AnyObject?

    override public func add(_ subscription: SubscriptionType) -> SubscriptionType {
        let subscr = super.add(subscription)
        if owned != nil {
            subscr.addOwnedObject(self)
        }
        return subscr
    }

    override public func add(_ handler: @escaping (T) -> Void) -> EventSubscription<T> {
        let subscr = super.add(handler)
        if owned != nil {
            subscr.addOwnedObject(self)
        }
        return subscr
    }

    override public func remove(_ subscription: SubscriptionType) {
        subscription.removeOwnedObject(self)
        super.remove(subscription)
    }

    override public func removeAll() {
        for subscription in event.subscriptions {
            subscription.removeOwnedObject(self)
        }
        super.removeAll()
    }

    override public func add(owner: AnyObject, _ handler: @escaping HandlerType) -> SubscriptionType {
        let subscr = super.add(owner: owner, handler)
        if owned != nil {
            subscr.addOwnedObject(self)
        }
        return subscr
    }

    override public init(event: Event<T>) {
        super.init(event: event)
    }
}
