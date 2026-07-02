from django.db import migrations


def create_homepage(apps, schema_editor):
    ContentType = apps.get_model("contenttypes.ContentType")
    Page = apps.get_model("wagtailcore.Page")
    Site = apps.get_model("wagtailcore.Site")
    Locale = apps.get_model("wagtailcore.Locale")
    HomePage = apps.get_model("cms.HomePage")

    # Delete the default "Welcome to Wagtail" page created by wagtailcore.
    Page.objects.filter(id=2).delete()

    homepage_content_type, _ = ContentType.objects.get_or_create(
        model="homepage", app_label="cms"
    )
    locale = Locale.objects.first()
    if locale is None:
        locale = Locale.objects.create(language_code="en")

    homepage = HomePage.objects.create(
        title="Nora",
        draft_title="Nora",
        slug="home",
        content_type=homepage_content_type,
        locale=locale,
        path="00010001",
        depth=2,
        numchild=0,
        url_path="/home/",
        intro="",
        live=True,
    )

    Site.objects.all().delete()
    Site.objects.create(
        hostname="localhost", root_page=homepage, is_default_site=True
    )


def remove_homepage(apps, schema_editor):
    HomePage = apps.get_model("cms.HomePage")
    HomePage.objects.filter(slug="home", depth=2).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("cms", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(create_homepage, remove_homepage),
    ]
