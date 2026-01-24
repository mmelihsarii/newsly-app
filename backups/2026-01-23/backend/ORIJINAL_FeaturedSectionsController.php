<?php

namespace App\Http\Controllers;

use App\Models\BreakingNews;
use App\Models\Category;
use App\Models\FeaturedSections;
use App\Models\Language;
use App\Models\News;
use App\Models\User;
use App\Services\ResponseService;
use Illuminate\Http\Request;
use Exception;
use Illuminate\Support\Facades\Validator;

class FeaturedSectionsController extends Controller
{
    public function index()
    {
        ResponseService::noAnyPermissionThenRedirect(['featured-section-list', 'featured-section-create', 'featured-section-edit', 'featured-section-delete', 'featured-section-order-create']);
        
        $languageList = Language::where('status', 1)->get();
        $categoryList = [];
        if (count($languageList) == 1) {
            $language_id = $languageList[0]->id;
            $categoryList = Category::select('id', 'category_name')->with('sub_categories')->where('language_id', $language_id)->get();
        }
        
        return view('featured_sections', compact('languageList', 'categoryList'));
    }

    public function get_feature_section_by_language(Request $request)
    {
        $language_id = $request->language_id;
        if ($language_id == 0) {
            $res = FeaturedSections::select('id', 'title')->orderBy('row_order', 'ASC')->get();
        } else {
            $res = FeaturedSections::select('id', 'title')->where('language_id', $language_id)->orderBy('row_order', 'ASC')->get();
        }
        $options = '';
        if (!empty($res)) {
            if ($request->sortable) {
                foreach ($res as $row) {
                    $options .= '<li id="' . $row->id . '">' . $row->title . '</li>';
                }
            }
        }
        return $options;
    }

    public function show(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-list');
        $offset = $request->input('offset', 0);
        $limit = $request->input('limit', 10);
        $sort = $request->input('sort', 'row_order');
        $order = $request->input('order', 'ASC');

        $sql = FeaturedSections::with('language');

        if ($request->has('search') && $request->search != '') {
            $search = $request->search;
            $sql = $sql->where(function ($q) use ($search) {
                $q->where('id', 'LIKE', "%{$search}%")
                    ->orwhere('title', 'LIKE', "%{$search}%")
                    ->orwhere('short_description', 'LIKE', "%{$search}%")
                    ->orwhere('news_type', 'LIKE', "%{$search}%")
                    ->orwhere('videos_type', 'LIKE', "%{$search}%")
                    ->orwhere('filter_type', 'LIKE', "%{$search}%");
            });
        }

        if ($request->has('language_id') && $request->language_id) {
            $sql = $sql->where('language_id', $request->language_id);
        }

        if ($request->has('status') && $request->status != '') {
            $sql->where('status', $request->status);
        }

        $total = $sql->count();

        $sql = $sql->skip($offset)->take($limit)->orderBy($sort, $order);

        $rows = $sql->get()->map(function ($row) {
            $edit = '';
            if (auth()->user()->can('featured-section-edit')) {
                $edit = '<a class="dropdown-item edit-data" data-toggle="modal" data-target="#editDataModal" title="' . __('edit') . '"><i class="fa fa-pen mr-1 text-primary"></i>' . __('edit') . '</a>';
            }

            $delete = '';
            if (auth()->user()->can('featured-section-delete')) {
                $delete = '<a data-url="' . url('featured_sections', $row->id) . '" class="dropdown-item delete-form" data-id="' . $row->id . '" title="' . __('delete') . '"><i class="fa fa-trash mr-1 text-danger"></i>' . __('delete') . '</a>';
            }

            $operate = '';
            if ($edit == '' && $delete == '') {
                $operate = '-';
            } else {
                $operate =
                    '<div class="dropdown"><a href="javascript:void(0)" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><button class="btn btn-primary btn-sm px-3"><i class="fas fa-ellipsis-v"></i></button></a><div class="dropdown-menu dropdown-scrollbar" aria-labelledby="dropdownMenuButton">' .
                    $edit .
                    $delete .
                    '</div></div>';
            }

            json_decode($row->meta_keyword);
            if (json_last_error() === JSON_ERROR_NONE) {
                $meta_keyword = json_decode($row->meta_keyword);
            } else {
                $meta_keyword = $row->meta_keyword;
            }

            $styleApp = [
                'style_1' => ['url' => 'App_Style_1.png', 'height' => 60, 'width' => 60],
                'style_2' => ['url' => 'App_Style_2.png', 'height' => 50, 'width' => 50],
                'style_3' => ['url' => 'App_Style_3.png', 'height' => 50, 'width' => 50],
                'style_4' => ['url' => 'App_Style_4.png', 'height' => 50, 'width' => 50],
                'style_5' => ['url' => 'App_Style_5.png', 'height' => 50, 'width' => 50],
                'style_6' => ['url' => 'App_Style_6.png', 'height' => 50, 'width' => 50],
            ];

            $style_app = '';
            if (array_key_exists($row->style_app, $styleApp)) {
                $style = $styleApp[$row->style_app];
                $style_app = '<a href="' . asset('images/app_style/' . $style['url']) . '" data-toggle="lightbox" data-title="Image"><img src="' . asset('images/app_style/' . $style['url']) . '" alt="' . $style_app . '" class="" height="' . $style['height'] . '" width="' . $style['width'] . '"></a>';
            }

            $styleWeb = [
                'style_1' => ['url' => 'Web_Style_1.png', 'height' => 40, 'width' => 100],
                'style_2' => ['url' => 'Web_Style_2.png', 'height' => 40, 'width' => 100],
                'style_3' => ['url' => 'Web_Style_3.png', 'height' => 40, 'width' => 100],
                'style_4' => ['url' => 'Web_Style_4.png', 'height' => 40, 'width' => 100],
                'style_5' => ['url' => 'Web_Style_5.png', 'height' => 40, 'width' => 100],
                'style_6' => ['url' => 'Web_Style_6.png', 'height' => 40, 'width' => 100],
            ];

            $style_web = '';
            if (array_key_exists($row->style_web, $styleWeb)) {
                $style = $styleWeb[$row->style_web];
                $style_web = '<a href="' . asset('images/app_style/' . $style['url']) . '" data-toggle="lightbox" data-title="Image"><img src="' . asset('images/app_style/' . $style['url']) . '" alt="' . $style_web . '" class="" height="' . $style['height'] . '" width="' . $style['width'] . '"></a>';
            }

            $news_type_badge = [
                'news' => __('news'),
                'breaking_news' => __('breaking_news'),
                'videos' => __('videos'),
            ];

            $filter_type_badge = [
                'most_commented' => __('most_commented'),
                'recently_added' => __('recently_added'),
                'most_viewed' => __('most_viewed'),
                'most_favorite' => __('most_favorite'),
                'most_like' => __('most_like'),
                'custom' => __('custom'),
            ];

            $video_type_badge = [
                'news' => __('news'),
                'breaking_news' => __('breaking_news'),
            ];

            return [
                'id' => $row->id,
                'language_id' => $row->language_id,
                'language' => $row->language->language ?? '',
                'title' => $row->title,
                'short_description' => mb_strimwidth($row->short_description, 0, 40, '...'),
                'short_description_full' => $row->short_description,
                'news_type' => $row->news_type ?? '',
                'news_type_badge' => $news_type_badge[$row->news_type] ?? '',
                'filter_type' => $row->filter_type ?? '',
                'filter_type_badge' => $filter_type_badge[$row->filter_type] ?? '',
                'category_id' => $row->category_ids ?? '',
                'subcategory_id' => $row->subcategory_ids ?? '',
                'news_id' => $row->news_ids ?? '',
                'style_app' => $style_app,
                'style_web' => $style_web,
                'row_order' => '<span class="btn btn-icon btn-sm btn-warning move" alt="Move" >' . $row->row_order . '</span>',
                'is_based_on_user_choice' => $row->is_based_on_user_choice ?? '',
                'created_at' => date('d-m-Y H:i:s', strtotime($row->created_at)),
                'updated_at' => date('d-m-Y H:i:s', strtotime($row->updated_at)),
                'videos_type' => $row->videos_type ?? '',
                'video_type_badge' => $video_type_badge[$row->videos_type] ?? '',
                'status1' => $row->status == '1' ? '<div class="badge badge-success">' . __('active') . '</div>' : '<div class="badge badge-danger">' . __('deactive') . '</div>',
                'status' => $row->status,
                'style_web_edit' => $row->style_web,
                'style_app_edit' => $row->style_app,
                'slug' => $row->slug,
                'meta_keyword' => $meta_keyword,
                'schema_markup' => $row->schema_markup,
                'og_image' => !empty($row->og_image) ? '<a href="' . $row->og_image . '" data-toggle="lightbox" data-title="Image"><img  class = "images_border" src="' . $row->og_image . '" height="50" width="50"></a>' : '-',
                'meta_title' => $row->meta_title,
                'meta_description' => $row->meta_description,
                'user_ids' => $row->user_ids ?? '',
                'operate' => $operate,
            ];
        });

        return response()->json([
            'total' => $total,
            'rows' => $rows,
        ]);
    }

    public function store(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-create');

        $validator = Validator::make($request->all(), [
            'language_id' => 'required',
            'title' => 'required|string|max:255',
            'slug' => 'required|string|max:255',
            'short_description' => 'required',
            'based_on_user_choice_mode' => 'required|in:0,1',
            'news_type' => 'required_if:based_on_user_choice_mode,0',
            'author_news_type' => 'required_if:news_type,author_news',
            'news_ids' => 'required_if:filter_type,custom&news_type,news',
            'style_app' => 'required|string',
            'style_web' => 'required|string',
        ]);

        if ($validator->fails()) {
            return ResponseService::errorResponse($validator->errors()->first(), null, 422, null);
        }

        $ids = $request->category_ids;
        $cat = [];
        $subcat = [];
        if (!empty($ids)) {
            foreach ($ids as $id) {
                $string = explode('-', $id);
                if ($string[0] == 'cat') {
                    array_push($cat, $string[1]);
                } elseif ($string[0] == 'subcat') {
                    array_push($subcat, $string[1]);
                }
            }
        }

        if (!empty($cat)) {
            $cat = implode(',', $cat);
        } else {
            $cat = '';
        }

        if (!empty($subcat)) {
            $subcat = implode(',', $subcat);
        } else {
            $subcat = '';
        }

        $news_ids = $request->news_ids;
        if (!empty($news_ids)) {
            $news_id = implode(',', $news_ids);
        }

        $user_ids = $request->author_news_type ?? null;
        if (!empty($user_ids)) {
            $user_ids = implode(',', $user_ids);
        }

        $slug = generateUniqueSlug($request->slug);

        $existingSlug = FeaturedSections::where('slug', $slug)->exists();
        if ($existingSlug) {
            $response = [
                'error' => true,
                'message' => __('slug_already_use'),
            ];
            return response()->json($response);
        }

        $feature_section = new FeaturedSections();
        $feature_section->language_id = $request->language_id ?? 0;
        $feature_section->title = $request->title;
        $feature_section->status = 1;
        $feature_section->short_description = $request->short_description;
        $feature_section->news_type = $request->news_type ?? '';
        $feature_section->videos_type = $request->videos_type ?? '';
        $feature_section->filter_type = $request->filter_type ?? '';
        $feature_section->category_ids = $cat ?? '';
        $feature_section->subcategory_ids = $subcat ?? '';
        $feature_section->news_ids = $news_id ?? '';
        $feature_section->style_app = $request->style_app;
        $feature_section->style_web = $request->style_web;
        $feature_section->slug = $slug;
        $feature_section->is_based_on_user_choice = $request->based_on_user_choice_mode ?? '';
        $feature_section->user_ids = $user_ids ?? null;

        if ($request->based_on_user_choice_mode) {
            $feature_section->news_ids = '';
            $feature_section->news_type = '';
            $feature_section->videos_type = '';
            $feature_section->filter_type = '';
        }

        if ($request->hasFile('file')) {
            $feature_section->og_image = compressAndUpload($request->file('file'), 'feature_section_og_image');
        } else {
            $feature_section->og_image = '';
        }

        $feature_section->schema_markup = $request->schema_markup ?? '';
        $feature_section->meta_title = $request->meta_title ?? '';
        $feature_section->meta_description = $request->meta_description ?? '';

        $meta_keyword = json_decode($request->meta_keyword, true);
        $feature_section->meta_keyword = $meta_keyword ? get_meta_keyword($meta_keyword) : '';

        $feature_section->save();

        $response = [
            'error' => false,
            'message' => __('created_success'),
        ];
        return response()->json($response);
    }

    public function update(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-edit');

        $rules = [
            'language_id' => 'required',
            'title' => 'required|string|max:255',
            'slug' => 'required|string|max:255',
            'short_description' => 'required|string',
        ];

        if ($request->edit_based_on_user_choice_mode == 0) {
            $rules['news_type'] = 'required';
            $rules['filter_type'] = 'required';
            if ($request->filter_type == 'custom' && $request->news_type != 'breaking_news') {
                $rules['news_ids'] = 'required';
            }
        }

        $request->validate($rules);

        $ids = $request->category_ids;
        $cat = [];
        $subcat = [];
        if (!empty($ids)) {
            foreach ($ids as $id) {
                $string = explode('-', $id);
                if ($string[0] == 'cat') {
                    array_push($cat, $string[1]);
                } elseif ($string[0] == 'subcat') {
                    array_push($subcat, $string[1]);
                }
            }
        }

        if (!empty($cat)) {
            $cat = implode(',', $cat);
        } else {
            $cat = '';
        }

        if (!empty($subcat)) {
            $subcat = implode(',', $subcat);
        } else {
            $subcat = '';
        }

        $user_ids = $request->author_news_type ?? null;
        if (!empty($user_ids)) {
            $user_ids = implode(',', $user_ids);
        }

        $news_ids = $request->news_ids;
        if (!empty($news_ids)) {
            $news_id = implode(',', $news_ids);
        }

        $slug = FeaturedSections::where('slug', $request->slug)->where('id', '!=', $request->edit_id)->first();
        if (!empty($slug)) {
            $response = [
                'error' => true,
                'message' => __('slug_already_use'),
            ];
            return response()->json($response);
        }

        if ($request->status == '1') {
            $status = 1;
        } else {
            $status = 0;
        }

        $feature_section = FeaturedSections::find($request->edit_id);
        $feature_section->language_id = $request->language_id ?? $feature_section->language_id;
        $feature_section->title = $request->title;
        $feature_section->short_description = $request->short_description;
        $feature_section->news_type = $request->news_type ?? '';
        $feature_section->videos_type = $request->videos_type ?? '';
        $feature_section->filter_type = $request->filter_type ?? '';
        $feature_section->category_ids = $cat ?? '';
        $feature_section->subcategory_ids = $subcat ?? '';
        $feature_section->news_ids = $news_id ?? '';
        $feature_section->style_app = $request->style_app;
        $feature_section->slug = generateUniqueSlug($request->slug);
        $feature_section->style_web = $request->style_web;
        $feature_section->status = $status;
        $feature_section->is_based_on_user_choice = isset($request->edit_based_on_user_choice_mode) ? $request->edit_based_on_user_choice_mode : 0;
        $feature_section->user_ids = $user_ids ?? null;

        if ($request->edit_based_on_user_choice_mode) {
            $feature_section->news_ids = '';
            $feature_section->news_type = '';
            $feature_section->videos_type = '';
            $feature_section->filter_type = '';
        }

        if ($request->hasFile('file')) {
            $feature_section->og_image = compressAndReplace($request->file('file'), 'feature_section_og_image', $feature_section->getRawOriginal('og_image'));
        }

        $feature_section->schema_markup = $request->schema_markup ?? '';
        $feature_section->meta_title = $request->meta_title ?? '';
        $feature_section->meta_description = $request->meta_description ?? '';

        $meta_keyword = json_decode($request->meta_keyword, true);
        $feature_section->meta_keyword = $meta_keyword ? get_meta_keyword($meta_keyword) : '';

        $feature_section->save();

        $response = [
            'error' => false,
            'message' => __('updated_success'),
        ];
        return response()->json($response);
    }

    public function destroy(string $id)
    {
        ResponseService::noPermissionThenRedirect('featured-section-delete');
        $feature_section = FeaturedSections::find($id);
        $feature_section->delete();

        $response = [
            'error' => false,
            'message' => __('deleted_success'),
        ];
        return response()->json($response);
    }

    public function get_categories_tree(Request $request)
    {
        $language_id = $request->language_id;
        $categories = Category::with('sub_categories')->where('language_id', $language_id)->get();

        $option = '<option value="0" disabled>' . __('select') . ' ' . __('category') . '</option>';
        foreach ($categories as $row) {
            $option .= '<option value="cat-' . $row->id . '">' . $row->category_name . '</option>';
            if (is_subcategory_enabled() == 1) {
                if ($language_id) {
                    $subcategories = $row->sub_categories->where('language_id', $language_id);
                } else {
                    $subcategories = $row->sub_categories;
                }
                foreach ($subcategories as $row1) {
                    $option .= '<option value="subcat-' . $row1->id . '">--' . $row1->subcategory_name . '</option>';
                }
            }
        }
        return $option;
    }

    public function getCustomNews(Request $request)
    {
        $languageId = $request->language_id;
        $newsType = $request->news_type;
        $option = '';
        $toDate = date('Y-m-d');

        if ($newsType == 'news') {
            $results = News::where('language_id', $languageId)
                ->where(function ($q) use ($toDate) {
                    $q->where('show_till', '>=', $toDate)->orWhere('show_till', '0000-00-00');
                })
                ->where('status', 1)
                ->where(function($q) use ($toDate) {
                    $q->where(function($subq) use ($toDate) {
                        $subq->whereNotNull('published_date')->where('published_date', '<=', $toDate);
                    })->orWhere(function($subq) use ($toDate) {
                        $subq->whereNull('published_date')->whereDate('created_at', '<=', $toDate);
                    });
                })
                ->get();
        } elseif ($newsType == 'breaking_news') {
            $results = BreakingNews::where('language_id', $languageId)->get();
        } elseif ($newsType == 'videos') {
            $videosType = $request->input('videos_type');
            $contentTypes = ['video_upload', 'video_youtube', 'video_other'];
            $results = News::where('language_id', $languageId)
                ->where(function ($q) use ($toDate) {
                    $q->where('show_till', '>=', $toDate)->orWhere('show_till', '0000-00-00');
                })
                ->where('status', 1)
                ->where(function($q) use ($toDate) {
                    $q->where(function($subq) use ($toDate) {
                        $subq->whereNotNull('published_date')->where('published_date', '<=', $toDate);
                    })->orWhere(function($subq) use ($toDate) {
                        $subq->whereNull('published_date')->whereDate('created_at', '<=', $toDate);
                    });
                })
                ->whereIn('content_type', $contentTypes)
                ->get();
        }

        if (!$results->isEmpty()) {
            foreach ($results as $res) {
                $option .= '<option value="' . $res->id . '">' . $res->title . '</option>';
            }
        }
        return $option;
    }

    public function update_order(Request $request)
    {
        ResponseService::noPermissionThenRedirect('featured-section-order-create');
        if ($request->row_order) {
            $row_order = explode(',', $request->row_order);
            foreach ($row_order as $key => $id) {
                FeaturedSections::where('id', $id)->update(['row_order' => $key + 1]);
            }
        }
        return redirect('featured_sections')->with('success', __('updated_success'));
    }

    public function getAuthorList()
    {
        $authors = User::where('is_author', 1)
            ->whereHas('news', function($query) {
                $query->where('is_draft', 0);
            })
            ->get(['id', 'name']);

        $option = '';
        foreach ($authors as $author) {
            $option .= '<option value="' . $author->id . '">' . $author->name . '</option>';
        }
        return $option;
    }

    // ============================================
    // FLUTTER API - YENİ FONKSİYON
    // ============================================
    public function getFeaturedSectionsForApp(Request $request)
    {
        try {
            $language_id = $request->input('language_id', 2);
            
            $sections = FeaturedSections::where('status', 1)
                ->where('language_id', $language_id)
                ->orderBy('row_order', 'ASC')
                ->get();
            
            if ($sections->isEmpty()) {
                return response()->json([
                    'success' => true,
                    'data' => [],
                ]);
            }
            
            $result = [];
            
            foreach ($sections as $section) {
                switch ($section->style_app) {
                    case 'style_1':
                    case 'style_6':
                        $type = 'slider';
                        break;
                    case 'style_4':
                        $type = 'breaking_news';
                        break;
                    default:
                        $type = 'horizontal_list';
                }
                
                $newsData = [];
                
                if ($section->news_type == 'breaking_news') {
                    $items = BreakingNews::where('language_id', $section->language_id)
                        ->where('status', 1)
                        ->orderBy('created_at', 'DESC')
                        ->take(10)
                        ->get();
                } else {
                    $query = News::where('status', 1)
                        ->where('language_id', $section->language_id);
                    
                    if ($section->filter_type == 'custom' && !empty($section->news_ids)) {
                        $ids = array_filter(explode(',', $section->news_ids));
                        if (!empty($ids)) {
                            $query->whereIn('id', $ids);
                        }
                    }
                    
                    if (!empty($section->category_ids)) {
                        $catIds = array_filter(explode(',', $section->category_ids));
                        if (!empty($catIds)) {
                            $query->whereIn('category_id', $catIds);
                        }
                    }
                    
                    // Sıralama - kolon varlığını kontrol etmeden güvenli sıralama
                    switch ($section->filter_type) {
                        case 'most_viewed':
                            // total_views yerine created_at kullan (kolon yoksa hata vermez)
                            $query->orderBy('created_at', 'DESC');
                            break;
                        case 'most_favorite':
                        case 'most_like':
                            // total_like yerine created_at kullan
                            $query->orderBy('created_at', 'DESC');
                            break;
                        default:
                            $query->orderBy('created_at', 'DESC');
                    }
                    
                    $items = $query->with('category')->take(10)->get();
                }
                
                foreach ($items as $item) {
                    $imageUrl = null;
                    if (!empty($item->image)) {
                        $imageUrl = (substr($item->image, 0, 4) === 'http') 
                            ? $item->image 
                            : url('storage/' . $item->image);
                    }
                    
                    $newsData[] = [
                        'id' => (string) $item->id,
                        'title' => $item->title ?? '',
                        'image' => $imageUrl,
                        'date' => $item->created_at ? $item->created_at->format('d M H:i') : '',
                        'categoryName' => isset($item->category) ? ($item->category->category_name ?? 'Gündem') : 'Gündem',
                        'description' => $item->short_description ?? '',
                        'sourceUrl' => $item->source_url ?? '',
                        'sourceName' => $item->source_name ?? '',
                    ];
                }
                
                if (!empty($newsData)) {
                    $result[] = [
                        'id' => $section->id,
                        'title' => $section->title,
                        'type' => $type,
                        'is_active' => true,
                        'order' => $section->row_order,
                        'news' => $newsData,
                    ];
                }
            }
            
            return response()->json([
                'success' => true,
                'data' => $result,
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'data' => [],
            ], 500);
        }
    }
}
