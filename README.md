Go CI Simple Admin Client
=========================

Extremely simple command-line tools for adding and removing Go CI pipelines, using the undocumented config file interface in Go CI.

Hopefully, this will be unnecessary with Go version 2.2.

Usage:
------

In all cases, create a client with auth credentials:

    updater = GoUpdater.new("go_user", "password")

Add a pipeline:

    updater.add_pipeline_for_branch("someproj", "git@example.com:foo/someproj.git", "rc-0.1.54", "rc")

Note that to add an RC pipeline of someproj, you'll need a template at: pipeline_templates/template_someproj_rc.xml

Delete a pipeline:

    updater.delete_pipeline("someproj_rc-0.1.59")

Rename a pipeline:

    updater.rename_pipeline("someproj_rc-0.1.56", "renamed_someproj_rc-0.1.56")

