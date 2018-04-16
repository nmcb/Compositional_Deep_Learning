{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE InstanceSigs #-}

import qualified CategoricDefinitions as Cat


----------------

instance Cat.Category (->) where
  id    = \a -> a
  g . f = \a -> g (f a)

instance Cat.Monoidal (->) where
  f `x` g = \(a, b) -> (f a, g b)

instance Cat.Cartesian (->) where
  exl = \(a, _) -> a
  exr = \(_, b) -> b
  dup = \a -> (a, a)

----------------

newtype D a b = D {eval :: a -> (b, a -> b)}

linearD :: (a -> b) -> D a b
linearD f = D $ \a -> (f a, f)

instance Cat.Category D where
  id      = linearD id
  g . f   = D $ \a -> let (b, f') = eval f a
                          (c, g') = eval g b
                      in (c, g' . f')

instance Cat.Monoidal D where
  f `x` g = D $ \(a, b) -> let (c, f') = eval f a
                               (d, g') = eval g b
                           in ((c, d), \(z1, z2) -> (f' z1, g' z2))

instance Cat.Cartesian D where
  exl = linearD fst
  exr = linearD snd
  dup = linearD $ \x -> (x, x)

t :: Cat.Cartesian k => (a `k` c) -> (a `k` d) -> (a `k` (c, d))
f `t` g = (f `Cat.x` g) Cat.. Cat.dup

v :: (Num a, Cat.Monoidal k, Cat.Cocartesian k) => (c `k` a) -> (d `k` a) -> ((c, d) `k` a)
f `v` g = Cat.jam Cat.. (f `Cat.x` g)

newtype a ->+ b = AddFun (a -> b)

instance Cat.Category (->+) where
  id = AddFun id
  (AddFun g) . (AddFun f) = AddFun (g . f)

instance Cat.Monoidal (->+) where
  (AddFun f) `x` (AddFun g) = AddFun (f `Cat.x` g)

instance Cat.Cartesian (->+) where
  exl = AddFun Cat.exl
  exr = AddFun Cat.exr
  dup = AddFun Cat.dup

instance Cat.Cocartesian (->+) where
  inl = AddFun $ \a -> (a, 0)
  inr = AddFun $ \b -> (0, b)
  jam = AddFun $ \(a, b) -> a + b

instance Num a => Cat.Scalable (->+) a where
  scale a = AddFun (\x -> a*x)
 
instance Num a => Cat.NumCat (->) a where
  negateC = negate
  addC = uncurry (+)
  mulC = uncurry (*)

instance Num a => Cat.NumCat D a where
  negateC = linearD Cat.negateC
  addC = linearD Cat.addC
  --mulC = D $ \(a, b) -> (a * b, (scale b) `v` (scale a))
