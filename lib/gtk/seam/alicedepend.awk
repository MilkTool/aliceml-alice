#
# alicedepend.awk does more or less the same as "alicedep --stockwerk".
# Well, a hundred times faster.
#
# Okay, it is not able to handle "x-alice:" URLs.
# So in the release version, the real alicedep should be used.
#

BEGIN { FS = "\""; }

function exists(file) {
  return ((getline var < file) > 0);
}

function dirname(file) {
  return (gensub(/[^\/]*$/, "", "g", file));
}

{
  if (match ($0, /^\w*import.*\".*\"\w*$/))
    depends[FILENAME] = depends[FILENAME] " \\\n         " \
      dirname(FILENAME) $2 (exists($2 ".asig") ? ".asig" : ".stc")
}

END {
  for (file in depends)
    print (gensub(/\.aml$/, ".stc", "g", file)) ":" depends[file] "\n"
}
