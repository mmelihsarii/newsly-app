@extends('layouts.main')

@section('title')
    {{ __('send_notification') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('notification') }}</h1>
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark">
                                <i class="fas fa-home mr-1"></i>{{ __('dashboard') }}
                            </a>
                        </li>
                        <li class="breadcrumb-item active">
                            <i class="nav-icon fas fa-bullhorn mr-1"></i>{{ __('send_notification') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('notification-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1">
                            <i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('notification') }}
                        </button>
                    </div>
                @endcan

                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('notification') }}</h3>
                        </div>
                        <form id="create_form" action="{{ url('notifications') }}" role="form" method="POST"
                            enctype="multipart/form-data">
                            @csrf
                            <div class="card-body">
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="language_id" name="language" class="form-control" required>
                                            @if (count($languageList) > 1)
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @endif
                                            @foreach ($languageList as $row)
                                                <option value="{{ $row->id }}">{{ $row->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('type') }}</label>
                                        <select id="type" name="type" class="form-control" required>
                                            <option value="default">{{ __('default') }}</option>
                                            @if($settings['category_mode'] == 1)
                                                <option value="category">{{ __('category') }}</option>
                                            @endif
                                        </select>
                                    </div>

                                    @if (is_location_news_enabled() == 1)
                                        <div class="form-group col-md-4 col-sm-12">
                                            <label>{{ __('location') }}</label>
                                            <select name="location_id" class="form-control">
                                                <option value="">{{ __('select') . ' ' . __('location') }}</option>
                                                @foreach ($locationList as $row)
                                                    <option value="{{ $row->id }}">{{ $row->location_name }}</option>
                                                @endforeach
                                            </select>
                                        </div>
                                    @endif
                                </div>

                                <!-- KATEGORİ BÖLÜMÜ - ALT KATEGORİ KALDIRILDI -->
                                <div class="row" id="type_category" style="display: none">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('category') }}</label>
                                        <select id="category_id" name="category_id" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                            @foreach ($categoryList as $row)
                                                <option value="{{ $row->id }}">{{ $row->category_name }}</option>
                                            @endforeach
                                        </select>
                                    </div>

                                    <!-- Alt kategori gizli alan olarak 0 gönder -->
                                    <input type="hidden" name="subcategory_id" value="0">

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('news') }} (Opsiyonel)</label>
                                        <select id="news_id" name="news_id" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('news') }} (Opsiyonel)</option>
                                        </select>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('title') }}</label>
                                        <input name="title" placeholder="{{ __('title') }}" type="text"
                                            class="form-control" required>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('message') }} </label>
                                        <textarea name="message" placeholder="{{ __('message') }}" required class="form-control"></textarea>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('image') }} </label>
                                        <input name="file" type="file" class="filepond">
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <div class="form-check form-switch d-flex align-items-center">
                                            <label class="mr-2">{{ __('category_preference') }}</label>
                                            <input type="hidden" id="is_user_category" name="is_user_category" value="0">
                                            <input type="checkbox" id="user_category_switch" name="user_category_switch"
                                                class="status-switch" disabled>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary">{{ __('submit') }} </button>
                            </div>
                        </form>
                    </div>
                </div>

                @can('notification-list')
                    <div class="col-md-12">
                        <div class="card card-secondary">
                            <div class="card-header">
                                <h3 class="card-title">{{ __('notification') . ' ' . __('list') }}</h3>
                            </div>
                            <div class="card-body">
                                <table aria-describedby="mydesc" id='table' data-toggle="table"
                                    data-url="{{ route('notificationList') }}" 
                                    data-locale="{{ session('locale') == 'hi' ? 'hi-IN' : 'en-US' }}" 
                                    data-click-to-select="true"
                                    data-side-pagination="server" data-pagination="true"
                                    data-page-list="[5, 10, 20, 50, 100, 200]" data-search="true" 
                                    data-show-columns="true"
                                    data-show-refresh="true" data-toolbar="#toolbar" 
                                    data-mobile-responsive="true"
                                    data-buttons-class="primary" data-trim-on-search="false" 
                                    data-sort-name="id"
                                    data-sort-order="desc" data-query-params="queryParams">
                                    <thead>
                                        <tr>
                                            <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                            <th scope="col" data-field="langauge_id" data-visible="false">{{ __('language_id') }}</th>
                                            <th scope="col" data-field="langauge_name">{{ __('language') }}</th>
                                            <th scope="col" data-field="category_name">{{ __('category') }}</th>
                                            <th scope="col" data-field="subcategory_name" data-visible="false">{{ __('subcategory') }}</th>
                                            <th scope="col" data-field="news_title">{{ __('news') }}</th>
                                            <th scope="col" data-field="title" data-sortable="true">{{ __('title') }}</th>
                                            <th scope="col" data-field="message" data-formatter="textFormatter">{{ __('message') }}</th>
                                            <th scope="col" data-field="image">{{ __('image') }}</th>
                                            <th scope="col" data-field="category_preference" data-visible="false">{{ __('category_preference') }}</th>
                                            <th scope="col" data-field="date">{{ __('created_at') }}</th>
                                            @canany(['notification-delete'])
                                                <th scope="col" data-field="operate" data-events="">{{ __('operate') }}</th>
                                            @endcanany
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    </div>
                @endcan
            </div>
        </div>
    </section>
@endsection

@section('script')
<script type="text/javascript">
    // AJAX ile liste çekme fonksiyonu
    function fetchList(url, data, targetSelector) {
        $.ajax({
            url: url,
            type: 'GET',
            data: data,
            dataType: 'json',
            success: function(response) {
                var $target = $(targetSelector);
                var defaultOption = $target.find('option:first').clone();
                
                $target.empty();
                $target.append(defaultOption);
                
                if (response && response.data && response.data.length > 0) {
                    $.each(response.data, function(index, item) {
                        var id = item.id;
                        var name = item.category_name || item.subcategory_name || item.title || item.name || '';
                        $target.append('<option value="' + id + '">' + name + '</option>');
                    });
                }
            },
            error: function(xhr, status, error) {
                console.error('Fetch error:', error);
            }
        });
    }

    // Dil değiştiğinde kategorileri yükle
    $(document).on('change', '#language_id', function(e) {
        var language_id = $(this).val();
        if (language_id) {
            var data = { language_id: language_id };
            var url = '{{ route('get_category_by_language') }}';
            fetchList(url, data, '#category_id');
            
            // Haberleri temizle
            $('#news_id').empty().append('<option value="">{{ __('select') . ' ' . __('news') }} (Opsiyonel)</option>');
        }
    });

    // Kategori değiştiğinde HABERLERİ DOĞRUDAN YÜKLE (alt kategori yok)
    $(document).on('change', '#category_id', function(e) {
        var category_id = $(this).val();
        
        if (category_id) {
            var data = { category_id: category_id };
            var url = '{{ route('get_news_by_category') }}';
            fetchList(url, data, '#news_id');
        } else {
            $('#news_id').empty().append('<option value="">{{ __('select') . ' ' . __('news') }} (Opsiyonel)</option>');
        }
    });

    // Tür değiştiğinde kategori alanını göster/gizle
    $(document).on('change', '#type', function() {
        var type = $(this).val();
        
        if (type == "default") {
            $("#type_category").hide();
            $("#category_id").prop('required', false);
            $("#news_id").prop('required', false);
        } else if (type == "category") {
            $("#type_category").show();
            $("#category_id").prop('required', true);
            // news_id artık zorunlu DEĞİL
            $("#news_id").prop('required', false);
        }
    });

    // Tablo query params
    function queryParams(p) {
        return {
            sort: p.sort,
            order: p.order,
            limit: p.limit,
            offset: p.offset,
            search: p.search,
        };
    }

    // Switchery
    $(document).ready(function() {
        var elems = Array.prototype.slice.call(document.querySelectorAll(".status-switch"));
        var userCategorySwitchery;

        elems.forEach(function(elem) {
            var switchery = new Switchery(elem, {
                size: "small",
                color: "#47C363",
                secondaryColor: "#EB4141",
                jackColor: "#ffff",
                jackSecondaryColor: "#ffff",
            });
            if (elem.id === 'user_category_switch') {
                userCategorySwitchery = switchery;
            }
        });

        var user_category_switch = document.querySelector('#user_category_switch');
        
        if (user_category_switch) {
            user_category_switch.onchange = function() {
                $('#is_user_category').val(user_category_switch.checked ? 1 : 0);
            };
        }

        $('#type').on('change', function() {
            var type = $(this).val();
            if (type === 'category' && userCategorySwitchery) {
                userCategorySwitchery.enable();
            } else if (userCategorySwitchery) {
                $('#is_user_category').val(0);
                userCategorySwitchery.disable();
            }
        });

        // Sayfa yüklendiğinde dil seçiliyse kategorileri yükle
        var initialLanguage = $('#language_id').val();
        if (initialLanguage) {
            setTimeout(function() {
                $('#language_id').trigger('change');
            }, 500);
        }
    });
</script>
@endsection
