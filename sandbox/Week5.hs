module Week5 where

import           Data.Foldable
import           Data.Ord
import           Data.Maybe

-- | Given a list of lists, returns the list with maximum length.
-- Throws if argument is empty.
longest :: Foldable f => f [a] -> [a]
longest = maximumBy (comparing length)

-- | Given two sequences, returns their longest common subsequence.
-- Here, a subsequence need not be contiguous.
lcs :: Eq a => [a] -> [a] -> [a]
lcs (x:xs) (y:ys)
  | x == y = x:lcs xs ys
  | otherwise = longest [lcs (x:xs) ys, lcs xs (y:ys)]
lcs _ _ = []

-- | Given a list, returns the list except the front and end elements.
trimEnds :: [a] -> [a]
trimEnds (_:xs) = reverse $ drop 1 $ reverse xs
trimEnds _ = []

type Partition = [String]

-- | Determines whether the given string is a palindrome.
isPalindrome :: String -> Bool
isPalindrome x = x == reverse x

-- | Prepends the character to the first part of the partition.
prependToPartition :: Char -> Partition -> Partition
prependToPartition x (p:ps) = (x:p):ps
prependToPartition x [] = [[x]]

-- | Determines whether the partition is non-empty and the first part is a palindrome.
headIsPalindrome :: Partition -> Bool
headIsPalindrome = maybe False isPalindrome . listToMaybe

-- palinPartitions "iiii" = [["i", "i", "i", "i"], ["ii", "ii"], ["i", "ii", "i"], ["iiii"]]
-- palinPartitions "nitin" = [["n", "i", "t", "i", "n"], ["n", "iti", "n"], ["nitin"]]
-- Partition string into partitions such that:
--  - the partitions concat to the full string, and
--  - for each partition, each element is palindromic.
-- Additionally, the partition elements are non-empty strings.
palinPartitions :: String -> [Partition]
palinPartitions = filter headIsPalindrome . go
  where
    go :: String -> [Partition]
    go [] = [[]]
    go (x:xs) = fmap ([x]:) restValid ++ (prependToPartition x <$> restNotNull)
      where
        rest = go xs

        restNotNull = filter (not . null) rest

        restValid = filter headIsPalindrome rest

-- | Implementation of palindromic partitions using foldr.
palinPartitions' :: String -> [Partition]
palinPartitions' = filter headIsPalindrome . foldr go [[]]
  where
    -- | Folds through a string and builds up a list of palindromic partitions.
    -- Given a character, first prefixes itself (as a single char string) to all
    -- valid partitions. A single character string is always palindromic.
    --
    -- Then, concats this with prepending c to the first part of all
    -- subsequent partitions which are (not necessarily palindromic). This
    -- builds up "possibly palindromic" partitions where the first part may
    -- not be palindromic but the rest are.
    --
    -- This allows us to handle cases like "aba" where "ba" is not palindromic
    -- but "aba" is. We cannot immediately discard this on "ba".
    --
    -- Therefore, the accumulator generated by this fold is a list of partitions
    -- whose parts are palindromic except possibly the first part. Hence, the
    -- filter on the final result of the fold.
    go :: Char -> [Partition] -> [Partition]
    go c [] = [[[c]]]
    go c rest = fmap ([c]:) restPalins ++ fmap (prependToPartition c) rest
      where
        restPalins = filter headIsPalindrome rest
