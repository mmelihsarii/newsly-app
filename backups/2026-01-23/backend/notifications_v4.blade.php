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
                                    <input type="hidden" name="subcategory_id" value="0">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('news') }}</label>
                                        <select id="news_id" name="news_id" class="form-control">
                                            <option value="">Önce kategori seçin</option>
                                        </select>
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('title') }}</label>
                                        <input name="title" id="notification_title" type="text" class="form-control" required>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('message') }}</label>
                                        <textarea name="message" id="notification_message" class="form-control" required></textarea>
                                    </div>
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('image') }}</label>
                                        <input name="file" type="file" class="filepond">
                                    </div>
                                </div>

                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <div class="form-check form-switch d-flex align-items-center">
                                            <label class="mr-2">{{ __('category_preference') }}</label>
                                            <input type="hidden" id="is_user_category" name="is_user_category" value="0">
                                            <input type="checkbox" id="user_category_switch" class="status-switch" disabled>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="card-footer">
                                <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
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
                                        <th data-field="message">{{ __('message') }}</th>
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
<script>
// Dil değiştiğinde kategorileri yükle
$(document).on('change', '#language_id', function() {
    var language_id = $(this).val();
    if (language_id) {
        // Panelin mevcut fetchList fonksiyonunu kullan
        var data = { language_id: language_id };
        var url = '{{ route("get_category_by_language") }}';
        fetchList(url, data, '#category_id');
    }
    // Haber listesini sıfırla
    $('#news_id').empty().append('<option value="">Önce kategori seçin</option>');
});

// Kategori değiştiğinde haberleri yükle - fetchList kullan (GET)
$(document).on('change', '#category_id', function() {
    var category_id = $(this).val();
    console.log('Kategori seçildi:', category_id);
    
    if (category_id) {
        // Panelin mevcut fetchList fonksiyonunu kullan (GET request)
        var data = { category_id: category_id };
        var url = '{{ route("get_news_by_category") }}';
        
        console.log('Haber yükleniyor, URL:', url);
        $('#news_id').empty().append('<option value="">Yükleniyor...</option>');
        
        // fetchList fonksiyonunu kullan
        fetchList(url, data, '#news_id');
    } else {
        $('#news_id').empty().append('<option value="">Önce kategori seçin</option>');
    }
});

// Haber seçildiğinde başlık ve mesajı otomatik doldur
$(document).on('change', '#news_id', function() {
    var selectedOption = $(this).find('option:selected');
    var title = selectedOption.text();
    
    if (title && title !== 'Haber Seçin' && title !== 'Önce kategori seçin' && title !== 'Yükleniyor...') {
        if ($('#notification_title').val() === '') {
            $('#notification_title').val(title.substring(0, 100));
        }
        if ($('#notification_message').val() === '') {
            $('#notification_message').val('Detaylar için tıklayın');
        }
    }
});

// Tip değiştiğinde kategori alanını göster/gizle
$(document).on('change', '#type', function() {
    if ($(this).val() == 'category') {
        $('#type_category').show();
        $('#category_id').prop('required', true);
        $('#news_id').prop('required', true);
    } else {
        $('#type_category').hide();
        $('#category_id').prop('required', false);
        $('#news_id').prop('required', false);
    }
});

// Tablo için query params
function queryParams(p) {
    return {
        sort: p.sort,
        order: p.order,
        limit: p.limit,
        offset: p.offset,
        search: p.search
    };
}

// Switchery başlat
$(document).ready(function() {
    var elems = document.querySelectorAll('.status-switch');
    elems.forEach(function(elem) {
        new Switchery(elem, {size: 'small', color: '#47C363'});
    });
    
    // user_category_switch için event
    var userSwitch = document.querySelector('#user_category_switch');
    if (userSwitch) {
        userSwitch.onchange = function() {
            $('#is_user_category').val(this.checked ? 1 : 0);
        };
    }
    
    // Type category olduğunda switch'i aktif et
    $('#type').on('change', function() {
        var userSwitch = document.querySelector('#user_category_switch');
        if (userSwitch && userSwitch.switchery) {
            if ($(this).val() === 'category') {
                userSwitch.switchery.enable();
            } else {
                userSwitch.switchery.disable();
            }
        }
    });
});
</script>
@endsection
