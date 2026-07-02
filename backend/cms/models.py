from django.db import models
from wagtail.admin.panels import FieldPanel
from wagtail.api import APIField
from wagtail.fields import RichTextField
from wagtail.models import Page
from wagtail.rich_text import expand_db_html
from wagtail.search import index


class HomePage(Page):
    intro = RichTextField(blank=True)

    content_panels = Page.content_panels + [FieldPanel("intro")]

    api_fields = [APIField("intro")]

    subpage_types = ["cms.BlogIndexPage", "cms.DesignPlanIndexPage"]


class BlogIndexPage(Page):
    intro = RichTextField(blank=True)

    content_panels = Page.content_panels + [FieldPanel("intro")]

    api_fields = [APIField("intro")]

    parent_page_types = ["cms.HomePage"]
    subpage_types = ["cms.BlogPage"]


class BlogPage(Page):
    date = models.DateField("Post date")
    intro = models.CharField(max_length=500, blank=True)
    body = RichTextField(blank=True)
    video_url = models.URLField(blank=True, help_text="YouTube video URL (optional)")

    search_fields = Page.search_fields + [
        index.SearchField("intro"),
        index.SearchField("body"),
    ]

    content_panels = Page.content_panels + [
        FieldPanel("date"),
        FieldPanel("intro"),
        FieldPanel("body"),
        FieldPanel("video_url"),
    ]

    api_fields = [
        APIField("date"),
        APIField("intro"),
        APIField("body_html"),
        APIField("video_url"),
    ]

    parent_page_types = ["cms.BlogIndexPage"]
    subpage_types = []

    @property
    def body_html(self):
        return expand_db_html(self.body)


class DesignPlanIndexPage(Page):
    intro = RichTextField(blank=True)

    content_panels = Page.content_panels + [FieldPanel("intro")]

    api_fields = [APIField("intro")]

    parent_page_types = ["cms.HomePage"]
    subpage_types = ["cms.DesignPlanPage"]


class DesignPlanPage(Page):
    intro = models.CharField(max_length=500, blank=True)
    body = RichTextField(blank=True)
    video_url = models.URLField(blank=True, help_text="YouTube video URL (optional)")

    search_fields = Page.search_fields + [
        index.SearchField("intro"),
        index.SearchField("body"),
    ]

    content_panels = Page.content_panels + [
        FieldPanel("intro"),
        FieldPanel("body"),
        FieldPanel("video_url"),
    ]

    api_fields = [
        APIField("intro"),
        APIField("body_html"),
        APIField("video_url"),
    ]

    parent_page_types = ["cms.DesignPlanIndexPage"]
    subpage_types = []

    @property
    def body_html(self):
        return expand_db_html(self.body)
