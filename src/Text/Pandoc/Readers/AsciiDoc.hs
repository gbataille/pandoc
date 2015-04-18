module Text.Pandoc.Readers.AsciiDoc (
  readAsciiDoc
) where

import qualified Data.Sequence as Seq
import Data.Monoid (mconcat, mempty)
import Control.Applicative ((<$>), (<$))
import Text.Pandoc.Definition
import Text.Pandoc.Options
import Text.Pandoc.Parsing
import qualified Text.Pandoc.Builder as B

type AsciiDocParser = Parser String ParserState

readAsciiDoc :: ReaderOptions
             -> String
             -> Pandoc
-- readAsciiDoc opts s = Pandoc (Meta (Map.singleton "foo" (MetaString "bar"))) []
readAsciiDoc opts s =
  (readWith parseAsciiDoc) def{ stateOptions = opts } (s ++ "\n\n")

parseAsciiDoc :: AsciiDocParser Pandoc
parseAsciiDoc = do
  -- markdown allows raw HTML
  blocks <- parseBlocks
  st <- getState
  let Pandoc _ bs = B.doc $ runF blocks st
  return $ Pandoc nullMeta bs

parseBlocks :: AsciiDocParser (F B.Blocks)
parseBlocks = mconcat <$> manyTill block eof

block :: AsciiDocParser (F B.Blocks)
block = do
  -- tr <- getOption readerTrace
  -- pos <- getPosition
  res <- choice [ mempty <$ blanklines
                -- TODO: gbataille - remove
                , fmap (return . B.Many . Seq.singleton . Para . (:[]) . Str) paragraph
             --   , return <$> (fmap (B.Many . Seq.singleton . Para . (:[]) . Str) anyLine)
--                , literalParagraph
--                , title
--                , documentTitle
--                , explicitId
--                , hrule
--                , pageBreak
--                , list
--                , labeledLine
--                , labeledMultiLine
--                , links
--                , image
--                , blockCode
-- --               , citation -- inline
--                , table
               ] <?> "wtf***"
  -- when tr $ do
  --   st <- getState
  --   trace (printf "line %d: %s" (sourceLine pos)
  --          (take 60 $ show $ B.toList $ runF res st)) (return ())
  return res

-- anyLine :: AsciiDocParser (F B.Blocks)
-- anyLine = anyChar


paragraph :: AsciiDocParser String
paragraph = manyTill (anyChar) (try $ newline >> many1 blankline)
