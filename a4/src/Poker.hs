module Poker where

--- do not change anything above this line ---

{--
You *MAY* use packages from base
https://hackage.haskell.org/package/base
but no others.

Suppose the following datatype for representing a standard deck of cards and
    data Suit = Hearts | Clubs | Diamonds | Spades deriving (Eq, Ord)
    data Rank = Numeric Int | Jack | Queens | King | Ace deriving (Eq, Ord)
    data Card = NormalCard Rank Suit | Joker deriving Eq

Your task is to determine the HAND RANKING of hand :: List[Card].  The HAND
RANKINGS in DESCENDING ORDER is given by:
    FiOAK -- five of a kind
    StFl  -- straight flush
    FoOAK -- four of a kind
    FuHo  -- full house
    Fl    -- flush
    St    -- straight
    TrOAK -- three of a kind
    TwPr  -- two pair
    OnPr  -- one pair
    HiCa  -- high card
where the definitions of the above are here: en.wikipedia.org/wiki/List_of_poker_hands
(Ignore the (**) note that says "Category does not exist under ace-to-five low rules")

Supposing
    data HandRanking = FiOAK | StFl | FoOAK | FuHo | Fl | St | TrOAK | TwPr | OnPr | HiCa deriving (Show, Eq, Ord)
write a function
    ranking :: (Card, Card, Card, Card, Card) -> HandRanking
that returns the GREATEST ranking among a hand of cards.


NOTES:

1/  Do *not* assume hands are drawn from a standard deck.  That is, presume any
    card can appear in duplicate.  In particular, assume any hand can have an
    arbitrary numbers of jokers in it.

2/  An Ace can be considered to have numeric rank 1 for the purposes of
    forming a straight or straight flush.

EXAMPLE
> ranking (Joker, Joker, Joker, Joker, Joker)
FiOAK

> ranking ((NormalCard Ace Hearts),
    (NormalCard (Numeric 2) Hearts),
    (NormalCard (Numeric 3) Hearts),
    (NormalCard (Numeric 4) Hearts),
    (NormalCard (Numeric 5) Hearts))
StFl

> ranking (Joker,
    (NormalCard (Numeric 2) Hearts),
    (NormalCard (Numeric 2) Spades),
    (NormalCard (Numeric 3) Hearts),
    Joker)
FoOAK
-- NOT FuHo because Full House has lower rank.
--}

import Data.List (sort, group)
import Data.Maybe (mapMaybe)
import Data.Semigroup (Arg(Arg))

data Suit = Hearts | Clubs | Diamonds | Spades deriving (Show, Eq, Ord, Enum, Bounded)
data Rank = Numeric Int | Jack | Queens | King | Ace deriving (Eq, Ord)
data Card = NormalCard Rank Suit | Joker deriving Eq

data HandRanking = FiOAK | StFl | FoOAK | FuHo | Fl | St | TrOAK | TwPr | OnPr | HiCa deriving (Show, Eq, Ord)

data Value = AL | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 | J | Q | K | AH
    deriving (Show, Eq, Ord, Enum, Bounded)

data Hand = Hand { handValues :: [Value], handSuits :: [Suit] } deriving (Show)

rankToValue :: Rank -> [Value]
rankToValue (Numeric 2) = [C2]
rankToValue (Numeric 3) = [C3]
rankToValue (Numeric 4) = [C4]
rankToValue (Numeric 5) = [C5]
rankToValue (Numeric 6) = [C6]
rankToValue (Numeric 7) = [C7]
rankToValue (Numeric 8) = [C8]
rankToValue (Numeric 9) = [C9]
rankToValue (Numeric 10) = [C10]
rankToValue Jack = [J]
rankToValue Queens = [Q]
rankToValue King = [K]
rankToValue Ace = [AL, AH]
rankToValue (Numeric x) = error $ "unknown numeric card rank: " ++ show x


toValues :: Card -> Maybe [Value]
toValues (NormalCard r _) = Just $ rankToValue r
toValues Joker = Nothing

toSuits :: Card -> Maybe Suit
toSuits (NormalCard _ s) = Just s
toSuits Joker = Nothing

-- predMaybe :: (Enum a, Bounded a) => a -> Maybe a
-- predMaybe x = guard (x /= minBound) $> pred x

-- succMaybe :: (Enum a, Bounded a) => a -> Maybe a
-- succMaybe x = guard (x /= maxBound) $> succ x

-- nearby :: (Enum a, Bounded a) => a -> [a]
-- nearby = catMaybes . sequence [predMaybe, pure, succMaybe]

-- resolveJokers :: [Card] -> [[Card]]
-- resolveJokers cs = (nonJokers++) <$> do
--     v <- nearVals
--     s <- suits
--     _
--     where numJokers = length $ filter (== Joker) cs
--           nonJokers = filter (/= Joker) cs
--           suits = nub $ concatMap toSuits nonJokers
--           vals = concatMap toValues nonJokers
--           nearVals = nub $ concatMap nearby vals

toHands :: [Card] -> [Hand]
toHands cs = do
    vs <- sequence $ mapMaybe toValues cs
    let ss = mapMaybe toSuits cs
    pure $ Hand (sort vs) (sort ss)

cardList :: (Card, Card, Card, Card, Card) -> [Card]
cardList (c1, c2, c3, c4, c5) = [c1, c2, c3, c4, c5]

isConsecutive :: (Ord a, Enum a, Bounded a) => [a] -> Bool
isConsecutive xs = and $ zipWith (\x y -> x < maxBound && succ x == y) xs xs'
    where xs' = drop 1 xs

frequencies :: Eq a => [a] -> [Int]
frequencies = sort . fmap length . group

rankHand :: Hand -> HandRanking
rankHand (Hand values suits)
  | maxCount == 5                  = FiOAK
  | consecutive && sameSuit        = StFl
  | maxCount == 4                  = FoOAK
  | maxCount == 3 && numRanks <= 2 = FuHo  -- [2, 3]
  | sameSuit                       = Fl
  | consecutive                    = St
  | maxCount == 3                  = TrOAK -- [1, 1, 3]
  | maxCount == 2 && numRanks <= 3 = TwPr  -- [1, 2, 2]
  | maxCount == 2                  = OnPr  -- [1, 1, 1, 2]
  | otherwise                      = HiCa
  where
    valCounts = frequencies values
    suitCounts = frequencies suits

    numJokers = 5 - length values
    maxCount = numJokers + maximum (0:valCounts)

    numRanks = length valCounts
    sameSuit = length suitCounts <= 1
    consecutive = isConsecutive values

arg :: (a -> b) -> a -> Arg b a
arg f x = Arg (f x) x

getArgVal :: Arg a b -> a
getArgVal (Arg x _) = x

bestHand :: [Card] -> Arg HandRanking Hand
bestHand = minimum . fmap (arg rankHand) . toHands

ranking :: (Card, Card, Card, Card, Card) -> HandRanking
ranking = getArgVal . bestHand . cardList

h1 :: (Card, Card, Card, Card, Card)
h1 = ((NormalCard Ace Hearts),
    (NormalCard (Numeric 2) Hearts),
    (NormalCard (Numeric 3) Hearts),
    (NormalCard (Numeric 4) Hearts),
    (NormalCard (Numeric 5) Hearts))