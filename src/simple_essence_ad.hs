{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}

import qualified Control.Category as Cat

class Cat.Category k => Monoidal k where
  x :: (a `k` c) -> (b `k` d) -> ((a, b) `k` (c, d)) 

class Monoidal k => Cartesian k where
  exl :: (a, b) `k` a
  exr :: (a, b) `k` b
  dup :: a `k` (a, a)

-- Error in the paper, in the paper cocartesian class requires just category and not monoidal?

class Monoidal k => Cocartesian k where
  inl :: a `k` (a, b)
  inr :: b `k` (a, b)
  jam :: (a, a) `k` a


newtype D a b = D {eval :: a -> (b, a -> b)}

linearD :: (a -> b) -> D a b
linearD f = D $ \a -> (f a, f)

instance Cat.Category D where
  id      = linearD id
  g . f   = D $ \a -> let (b, f') = eval f a
                          (c, g') = eval g b
                      in (c, g' . f')

instance Monoidal D where
  f `x` g = D $ \(a, b) -> let (c, f') = eval f a
                               (d, g') = eval g b
                           in ((c, d), \(z1, z2) -> (f' z1, g' z2))

instance Cartesian D where
  exl = linearD fst
  exr = linearD snd
  dup = linearD $ \x -> (x, x)

t :: Cartesian k => (a `k` c) -> (a `k` d) -> (a `k` (c, d))
f `t` g = (f `x` g) Cat.. dup

v :: Cocartesian k => (c `k` a) -> (d `k` a) -> ((c, d) `k` a)
f `v` g = jam Cat.. (f `x` g)

newtype a ->+ b = AddFun (a -> b)

instance Monoidal (->) where
  f `x` g = \(a, b) -> (f a, g b)

instance Cat.Category (->+) where
  id = AddFun id
  (AddFun g) . (AddFun f) = AddFun (g . f)

instance Monoidal (->+) where
  (AddFun f) `x` (AddFun g) = AddFun (f `x` g)

--instance Cartesian (->+) where
--  exl = AddFun exl
--  exr = AddFun exr
--  dup = AddFun dup


{-
class NumCat k a where
  negateC :: a `k` a
  addC :: (a, a) `k` a
  mulC :: (a, a) `k` a
 
instance Num a => NumCat (->) a where
  negateC = negate
  addC = uncurry (+)
  mulC = uncurry (*)

instance Num a => NumCat D a where
  negateC = linearD negateC
  addC = linearD addC
  mulC = D $ \(a, b) -> (a * b, )
 
-}
