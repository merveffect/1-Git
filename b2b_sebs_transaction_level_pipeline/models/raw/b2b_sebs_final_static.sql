SELECT
  * EXCEPT(Item_name___GA4__Google_Analytics, Item_category___GA4__Google_Analytics),

Item_name___GA4__Google_Analytics as item_name,

Item_category___GA4__Google_Analytics as item_category

from {{ source('funnel_exports', 'b2b_sebs_final') }}   