from pathlib import Path

script_path = Path('tool/apply_fakemon_advanced_core.py')
source = script_path.read_text(encoding='utf-8')
start_marker = "replace_once(\n    path,\n    \"\"\"}\n\"\"\",\n"
end_marker = "# Bump application version for the feature release."
start = source.index(start_marker)
end = source.index(end_marker, start)
replacement = r'''source = Path(path).read_text(encoding='utf-8').rstrip()
helper = """

class _ResolvedCustomReference {
  const _ResolvedCustomReference({
    required this.name,
    required this.pokemonId,
    required this.stableId,
    required this.definition,
  });

  final String name;
  final int? pokemonId;
  final String? stableId;
  final dynamic definition;
}
"""
Path(path).write_text(source + helper, encoding='utf-8')

'''
source = source[:start] + replacement + source[end:]
exec(compile(source, str(script_path), 'exec'))
