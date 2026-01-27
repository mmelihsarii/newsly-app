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
                        <form id="create_form" action="{{ url('notifications') }}" method="POST" enctype="multipart/form-data">
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
                                        <label class="required">{{ __('category') }}</label>
                                        <select id="category_id" name="category_id" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('category') }}</option>
                                            @foreach ($categoryList as $row)
                                                <option value="{{ $row->id }}">{{ $row->category_name }}</option>
                                            @endforeach
                                        </select>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('news') }}</label>
                                        <select id="news_id" name="news_id" class="form-control" required>
                                            <option value="">Önce kategori seçin</option>
                                        </select>
                                    </div>
                                </div>

                                <!-- Seçilen Haber Önizleme -->
                                <div class="row" id="news_preview" style="display: none;">
                                    <div class="col-md-12">
                                        <div class="card bg-light">
                                            <div class="card-body">
                                                <div class="row">
                                                    <div class="col-md-3">
                                                        <img id="preview_image" src="" class="img-fluid rounded" style="max-height: 150px; object-fit: cover;">
                                                    </div>
                                                    <div class="col-md-9">
                                                        <h5 id="preview_title" class="text-primary"></h5>
                                                        <p id="preview_description" class="text-muted small"></p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Hidden fields - otomatik doldurulacak -->
                                <input type="hidden" name="type" value="category">
                                <input type="hidden" name="subcategory_id" value="0">
                                <input type="hidden" name="title" id="notification_title">
                                <input type="hidden" name="message" id="notification_message">
                                <input type="hidden" name="news_image" id="news_image">

                                @if (is_location_news_enabled() == 1)
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('location') }}</label>
                                        <select name="location_id" class="form-control">
                                            <option value="">{{ __('select') . ' ' . __('location') }}</option>
                                            @foreach ($locationList as $row)
                                                <option value="{{ $row->id }}">{{ $row->location_name }}</option>
                                            @endforeach
                                        </select>
                                    </div>
                                </div>
                                @endif

                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <div class="form-check form-switch d-flex align-items-center">
                                            <label class="mr-2">{{ __('category_preference') }}</label>
                                            <input type="hidden" id="is_user_category" name="is_user_category" value="0">
                                            <input type="checkbox" id="user_category_switch" class="status-switch">
                                        </div>
                                        <small class="text-muted">Sadece bu kategoriyi takip edenlere gönder</small>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary" id="submit_btn" disabled>
                                    <i class="fas fa-paper-plane mr-2"></i>{{ __('submit') }}
                                </button>
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
                            <table id='table' data-toggle="table" data-url="{{ route('notificationList') }}"
                                data-side-pagination="server" data-pagination="true" data-page-list="[5,10,20,50]"
                                data-search="true" data-show-columns="true" data-show-refresh="true"
                                data-sort-name="id" data-sort-order="desc" data-query-params="queryParams">
                                <thead>
                                    <tr>
                                        <th data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th data-field="langauge_name">{{ __('language') }}</th>
                                        <th data-field="category_name">{{ __('category') }}</th>
                                        <th data-field="news_title">{{ __('news') }}</th>
                                        <th data-field="title" data-sortable="true">{{ __('title') }}</th>
                                        <th data-field="image">{{ __('image') }}</th>
                                        <th data-field="date">{{ __('created_at') }}</th>
                                        @can('notification-delete')
                                        <th data-field="operate">{{ __('operate') }}</th>
                                        @endcan
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
// Dil değiştiğinde kategorileri yükle
$(document).on('change', '#language_id', function(e) {
    var language_id = $('#language_id').val();
    var data = { language_id: language_id };
    var url = '{{ route('get_category_by_language') }}';
    fetchList(url, data, '#category_id');
    
    // Haber listesini ve önizlemeyi sıfırla
    $('#news_id').html('<option value="">Önce kategori seçin</option>');
    $('#news_preview').hide();
    $('#submit_btn').prop('disabled', true);
});

// Kategori değiştiğinde haberleri yükle
$(document).on('change', '#category_id', function(e) {
    var category_id = $('#category_id').val();
    
    if (category_id) {
        var data = { category_id: category_id };
        var url = '{{ route('get_news_by_category') }}';
        fetchList(url, data, '#news_id');
    } else {
        $('#news_id').html('<option value="">Önce kategori seçin</option>');
    }
    
    // Önizlemeyi sıfırla
    $('#news_preview').hide();
    $('#submit_btn').prop('disabled', true);
});

// Haber seçildiğinde detayları getir ve önizleme göster
$(document).on('change', '#news_id', function() {
    var news_id = $(this).val();
    
    if (news_id) {
        // AJAX ile haber detaylarını getir
        $.ajax({
            url: '{{ route('get_news_details_for_notification') }}',
            type: 'POST',
            data: {
                _token: '{{ csrf_token() }}',
                news_id: news_id
            },
            success: function(response) {
                if (response.error === false) {
                    var news = response.data;
                    
                    // Hidden alanlara yaz
                    $('#notification_title').val(news.title);
                    $('#notification_message').val(news.description);
                    $('#news_image').val(news.image);
                    
                    // Önizleme göster
                    $('#preview_title').text(news.title);
                    $('#preview_description').text(news.description);
                    
                    if (news.image) {
                        $('#preview_image').attr('src', news.image).show();
                    } else {
                        $('#preview_image').hide();
                    }
                    
                    $('#news_preview').show();
                    $('#submit_btn').prop('disabled', false);
                } else {
                    alert('Haber detayları alınamadı');
                    $('#submit_btn').prop('disabled', true);
                }
            },
            error: function() {
                alert('Bir hata oluştu');
                $('#submit_btn').prop('disabled', true);
            }
        });
    } else {
        $('#news_preview').hide();
        $('#submit_btn').prop('disabled', true);
    }
});

function queryParams(p) {
    return {
        sort: p.sort,
        order: p.order,
        limit: p.limit,
        offset: p.offset,
        search: p.search,
    };
}

$(document).ready(function() {
    // Switchery başlat
    var elems = Array.prototype.slice.call(document.querySelectorAll(".status-switch"));
    
    elems.forEach(function(elem) {
        var switchery = new Switchery(elem, {
            size: "small",
            color: "#47C363",
            secondaryColor: "#EB4141",
            jackColor: "#ffff",
            jackSecondaryColor: "#ffff",
        });
    });

    var user_category_switch = document.querySelector('#user_category_switch');
    if(user_category_switch) {
        user_category_switch.onchange = function() {
            if (user_category_switch.checked) {
                $('#is_user_category').val(1);
            } else {
                $('#is_user_category').val(0);
            }
        };
    }
});
</script>
@endsection
