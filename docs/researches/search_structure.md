```json
{
  "kind": "Listing",
  "data": {
    "after": "string | null",
    "dist": "number | null",
    "modhash": "string",
    "geo_filter": "string",
    "facets": "object",
    "before": "string | null",
    "children": [
      {
        "kind": "t3",
        "data": {
          "approved_at_utc": "any | null",
          "subreddit": "string",
          "selftext": "string",
          "user_reports": "array",
          "saved": "boolean",
          "mod_reason_title": "any | null",
          "gilded": "number",
          "clicked": "boolean",
          "is_gallery": "boolean",
          "title": "string",
          "link_flair_richtext": "array of objects",
          "subreddit_name_prefixed": "string",
          "hidden": "boolean",
          "pwls": "number",
          "link_flair_css_class": "string",
          "downs": "number",
          "thumbnail_height": "number",
          "top_awarded_type": "any | null",
          "name": "string",
          "media_metadata": "object",
          "hide_score": "boolean",
          "quarantine": "boolean",
          "link_flair_text_color": "string",
          "upvote_ratio": "number",
          "author_flair_background_color": "string | null",
          "ups": "number",
          "domain": "string",
          "media_embed": "object",
          "thumbnail_width": "number",
          "author_flair_template_id": "string | null",
          "is_original_content": "boolean",
          "author_fullname": "string",
          "secure_media": "any | null",
          "is_reddit_media_domain": "boolean",
          "is_meta": "boolean",
          "category": "any | null",
          "secure_media_embed": "object",
          "gallery_data": "object",
          "link_flair_text": "string",
          "can_mod_post": "boolean",
          "score": "number",
          "approved_by": "any | null",
          "is_created_from_ads_ui": "boolean",
          "author_premium": "boolean",
          "thumbnail": "string",
          "edited": "boolean | number",
          "author_flair_css_class": "string | null",
          "author_flair_richtext": "array",
          "gildings": "object",
          "content_categories": "any | null",
          "is_self": "boolean",
          "subreddit_type": "string",
          "created": "number",
          "link_flair_type": "string",
          "wls": "number",
          "removed_by_category": "any | null",
          "banned_by": "any | null",
          "author_flair_type": "string",
          "total_awards_received": "number",
          "allow_live_comments": "boolean",
          "selftext_html": "string | null",
          "likes": "any | null",
          "suggested_sort": "string | null",
          "banned_at_utc": "any | null",
          "url_overridden_by_dest": "string",
          "view_count": "any | null",
          "archived": "boolean",
          "no_follow": "boolean",
          "is_crosspostable": "boolean",
          "pinned": "boolean",
          "over_18": "boolean",
          "all_awardings": "array",
          "awarders": "array",
          "media_only": "boolean",
          "link_flair_template_id": "string",
          "can_gild": "boolean",
          "spoiler": "boolean",
          "locked": "boolean",
          "author_flair_text": "string | null",
          "treatment_tags": "array",
          "visited": "boolean",
          "removed_by": "any | null",
          "mod_note": "any | null",
          "distinguished": "string | null",
          "subreddit_id": "string",
          "author_is_blocked": "boolean",
          "mod_reason_by": "any | null",
          "num_reports": "any | null",
          "removal_reason": "any | null",
          "link_flair_background_color": "string",
          "id": "string",
          "is_robot_indexable": "boolean",
          "num_duplicates": "number",
          "report_reasons": "any | null",
          "author": "string",
          "discussion_type": "any | null",
          "num_comments": "number",
          "send_replies": "boolean",
          "media": "any | null",
          "contest_mode": "boolean",
          "author_patreon_flair": "boolean",
          "author_flair_text_color": "string | null",
          "permalink": "string",
          "stickied": "boolean",
          "url": "string",
          "subreddit_subscribers": "number",
          "created_utc": "number",
          "num_crossposts": "number",
          "mod_reports": "array",
          "is_video": "boolean"
        }
      }
    ]
  }
}
```

```typescript
// Reddit API Search Response Structure

// Qidiruv natijasi faqat bitta obyektdan (Listing) iborat bo'ladi, massiv emas.
export interface SearchResponse {
  kind: "Listing";
  data: SearchListingData;
}

export interface SearchListingData {
  after: string | null;
  dist: number | null;
  modhash: string;
  geo_filter: string;
  facets: Record<string, any>; // Qidiruv uchun maxsus qo'shilgan maydon
  children: Array<PostChild>;  // Faqat Postlar keladi
  before: string | null;
}

// -----------------------------------------------------
// Post Obyekti (t3) - Oddiy postniki bilan deyarli bir xil
// -----------------------------------------------------
export interface PostChild {
  kind: "t3";
  data: PostData;
}

export interface PostData {
  approved_at_utc: any | null;
  subreddit: string;
  selftext: string;
  user_reports: any[];
  saved: boolean;
  mod_reason_title: any | null;
  gilded: number;
  clicked: boolean;
  is_gallery?: boolean;
  title: string;
  link_flair_richtext: Array<{ e: string; t: string }>;
  subreddit_name_prefixed: string;
  hidden: boolean;
  pwls: number;
  link_flair_css_class: string;
  downs: number;
  thumbnail_height?: number;
  top_awarded_type: any | null;
  name: string;
  media_metadata?: Record<string, any>;
  hide_score: boolean;
  quarantine: boolean;
  link_flair_text_color: string;
  upvote_ratio: number;
  author_flair_background_color: string | null;
  ups: number;
  domain: string;
  media_embed: Record<string, any>;
  thumbnail_width?: number;
  author_flair_template_id: string | null;
  is_original_content: boolean;
  author_fullname: string;
  secure_media: any | null;
  is_reddit_media_domain: boolean;
  is_meta: boolean;
  category: any | null;
  secure_media_embed: Record<string, any>;
  gallery_data?: {
    items: Array<{ is_deleted: boolean; media_id: string; id: number }>;
  };
  link_flair_text: string | null;
  can_mod_post: boolean;
  score: number;
  approved_by: any | null;
  is_created_from_ads_ui: boolean;
  author_premium: boolean;
  thumbnail: string;
  edited: boolean | number;
  author_flair_css_class: string | null;
  author_flair_richtext: any[];
  gildings: Record<string, any>;
  content_categories: any | null;
  is_self: boolean;
  subreddit_type: string;
  created: number;
  link_flair_type: string;
  wls: number;
  removed_by_category: any | null;
  banned_by: any | null;
  author_flair_type: string;
  total_awards_received: number;
  allow_live_comments: boolean;
  selftext_html: string | null;
  likes: any | null;
  suggested_sort: string | null;
  banned_at_utc: any | null;
  url_overridden_by_dest?: string;
  view_count: any | null;
  archived: boolean;
  no_follow: boolean;
  is_crosspostable: boolean;
  pinned: boolean;
  over_18: boolean;
  all_awardings: any[];
  awarders: any[];
  media_only: boolean;
  link_flair_template_id?: string;
  can_gild: boolean;
  spoiler: boolean;
  locked: boolean;
  author_flair_text: string | null;
  treatment_tags: any[];
  visited: boolean;
  removed_by: any | null;
  mod_note: any | null;
  distinguished: string | null;
  subreddit_id: string;
  author_is_blocked: boolean;
  mod_reason_by: any | null;
  num_reports: any | null;
  removal_reason: any | null;
  link_flair_background_color: string;
  id: string;
  is_robot_indexable: boolean;
  num_duplicates: number;
  report_reasons: any | null;
  author: string;
  discussion_type: any | null;
  num_comments: number;
  send_replies: boolean;
  media: any | null;
  contest_mode: boolean;
  author_patreon_flair: boolean;
  author_flair_text_color: string | null;
  permalink: string;
  stickied: boolean;
  url: string;
  subreddit_subscribers: number;
  created_utc: number;
  num_crossposts: number;
  mod_reports: any[];
  is_video: boolean;
}
```
