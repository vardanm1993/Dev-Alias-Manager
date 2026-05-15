# Custom Aliases

Create aliases with the same registry that built-in packs use. Every alias has a category, kind, command, and description.

```bash
dam new
dam add NAME KIND 'COMMAND' 'DESCRIPTION'
dam add-to CATEGORY NAME KIND 'COMMAND' 'DESCRIPTION'
dam change CATEGORY NAME KIND 'COMMAND' 'DESCRIPTION'
dam remove NAME
dam search WORD
dam help alias NAME
```

Kinds:

```text
artisan   php artisan locally, or Sail artisan when Sail exists
npm       npm locally, or Sail npm when Sail exists
composer  Composer locally, or Sail composer when Sail exists
php       PHP locally, or Sail PHP when Sail exists
vendor    tools in ./vendor/bin
system    normal shell commands
raw       advanced shell workflows
```

Examples:

```bash
dam add-to sail myup raw '_dam_sail_command up -d' 'Start Sail'
dam add-to laravel myroutes artisan 'route:list' 'Show routes'
dam add hello system 'printf' 'Print text'
```
