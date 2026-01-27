@extends('layouts.main')

@section('title')
    {{ __('live_streaming') }}
@endsection

@section('content')
    <section class="content-header">
        <div class="container-fluid">
            <div class="row mb-2">
                <div class="col-sm-6">
                    <h1 class="m-0">{{ __('create_and_manage') . ' ' . __('live_streaming') }}</h1>
                    @if (is_live_streaming_enabled() == 0)
                        <label class="badge badge-danger">{{ __('disabled') }}</label>
                    @endif
                </div>
                <div class="col-sm-6">
                    <ol class="breadcrumb float-sm-right">
                        <li class="breadcrumb-item text-dark">
                            <a href="{{ route('home') }}" class="text-dark">
                                <i class="fas fa-home mr-1"></i>{{ __('dashboard') }}
                            </a>
                        </li>
                        <li class="breadcrumb-item active">
                            <i class="nav-icon fas fa-stream mr-1"></i>{{ __('live_streaming') }}
                        </li>
                    </ol>
                </div>
            </div>
        </div>
    </section>

    <section class="content">
        <div class="container-fluid">
            <div class="row">
                @can('live-streaming-create')
                    <div class="col-md-12 d-flex justify-content-end">
                        <button id="toggleButton" class="btn btn-primary mb-3 ml-1">
                            <i class="fas fa-plus-circle mr-2"></i>{{ __('create') . ' ' . __('live_streaming') }}
                        </button>
                    </div>
                @endcan

                <div class="col-md-12" id="add_card">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('create') . ' ' . __('live_streaming') }}</h3>
                        </div>
                        <div class="card-body">
                            <form id="create_form" action="{{ route('live_streaming.store') }}" role="form" method="POST" enctype="multipart/form-data">
                                @csrf
                                <div class="row">
                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="language" name="language" class="form-control" required>
                                            @if (count($languageList) > 1)
                                                <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @endif
                                            @foreach ($languageList as $item)
                                                <option value="{{ $item->id }}" data-name="{{ $item->language }}">{{ $item->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('title') }}</label>
                                        <input type="text" id="title" name="title" class="form-control" placeholder="{{ __('title') }}" required>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('type') }}</label>
                                        <select name="type" id="type" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('type') }}</option>
                                            <option value="url_youtube">{{ __('youtube_url') }}</option>
                                            <option value="url_other">{{ __('other_url') }}</option>
                                        </select>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="required">{{ __('URL') }}</label>
                                        <input type="url" name="url" class="form-control" placeholder="{{ __('URL') }}" required>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('image') }} / Logo</label>
                                        <input name="file" type="file" class="filepond" accept="image/*">
                                        <small class="text-muted">Kanal logosu veya kapak resmi</small>
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label class="mr-2">{{ __('schema_markup') }}</label>
                                        <input type="text" name="schema_markup" class="form-control" id="schema_markup" placeholder="{{ __('schema_markup') }}">
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('meta_keywords') }}</label>
                                        <input id="meta_tags" style="border-radius: 0.25rem" class="w-100" type="text" name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('meta_title') }}</label>
                                        <input type="text" name="meta_title" class="form-control" id="meta_title" placeholder="{{ __('meta_title') }}">
                                    </div>

                                    <div class="form-group col-md-4 col-sm-12">
                                        <label>{{ __('meta_description') }}</label>
                                        <textarea id="meta_description" name="meta_description" class="form-control"></textarea>
                                    </div>
                                </div>

                                <div class="d-flex justify-content-end">
                                    <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>

                @can('live-streaming-list')
                <div class="col-md-12">
                    <div class="card card-secondary">
                        <div class="card-header">
                            <h3 class="card-title">{{ __('live_streaming') . ' ' . __('list') }}</h3>
                        </div>
                        <div class="card-body">
                            <div id="toolbar">
                                <select id="filter_language_id" class="form-control">
                                    <option value="0">{{ __('select') . ' ' . __('language') }}</option>
                                    @foreach ($languageList as $row)
                                        <option value="{{ $row->id }}">{{ $row->language }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <table aria-describedby="mydesc" id='table' 
                                data-toggle="table" 
                                data-url="{{ route('liveStreamingList') }}" 
                                data-click-to-select="true" 
                                data-side-pagination="server" 
                                data-pagination="true" 
                                data-page-list="[5, 10, 20, 50, 100]" 
                                data-search="true"
                                data-show-columns="true" 
                                data-show-refresh="true" 
                                data-toolbar="#toolbar" 
                                data-mobile-responsive="true" 
                                data-sort-name="id" 
                                data-sort-order="desc" 
                                data-query-params="queryParams">
                                <thead>
                                    <tr>
                                        <th scope="col" data-field="id" data-sortable="true">{{ __('id') }}</th>
                                        <th scope="col" data-field="language_id" data-visible="false">{{ __('language_id') }}</th>
                                        <th scope="col" data-field="language">{{ __('language') }}</th>
                                        <th scope="col" data-field="image" data-formatter="imageFormatter">{{ __('image') }}</th>
                                        <th scope="col" data-field="title" data-sortable="true">{{ __('title') }}</th>
                                        <th scope="col" data-field="type">{{ __('type') }}</th>
                                        <th scope="col" data-field="url">{{ __('URL') }}</th>
                                        <th scope="col" data-field="image_url" data-visible="false">image_url</th>
                                        <th scope="col" data-field="url_raw" data-visible="false">url_raw</th>
                                        <th scope="col" data-field="type1" data-visible="false">type1</th>
                                        <th scope="col" data-field="schema_markup" data-visible="false">{{ __('schema_markup') }}</th>
                                        <th scope="col" data-field="meta_keyword" data-visible="false">{{ __('meta_keywords') }}</th>
                                        <th scope="col" data-field="meta_title" data-visible="false">{{ __('meta_title') }}</th>
                                        <th scope="col" data-field="meta_description" data-visible="false">{{ __('meta_description') }}</th>
                                        @canany(['live-streaming-edit', 'live-streaming-delete'])
                                            <th scope="col" data-field="operate" data-events="actionEvents">{{ __('operate') }}</th>
                                        @endcanany
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
                @endcan
            </div>

            <!-- Edit Modal -->
            <div class="modal fade" id="editDataModal">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h4 class="modal-title">{{ __('edit') . ' ' . __('live_streaming') }}</h4>
                            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                        <form id="update_form" action="" method="POST" enctype="multipart/form-data">
                            @csrf
                            @method('PUT')
                            <input type='hidden' name="edit_id" id="edit_id" value='' />
                            
                            <div class="modal-body">
                                <div class="row">
                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('language') }}</label>
                                        <select id="edit_language" name="language" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('language') }}</option>
                                            @foreach ($languageList as $item)
                                                <option value="{{ $item->id }}">{{ $item->language }}</option>
                                            @endforeach
                                        </select>
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('title') }}</label>
                                        <input type="text" name="title" id="edit_title" class="form-control" placeholder="{{ __('title') }}" required>
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('type') }}</label>
                                        <select name="type" id="edit_type" class="form-control" required>
                                            <option value="">{{ __('select') . ' ' . __('type') }}</option>
                                            <option value="url_youtube">{{ __('youtube_url') }}</option>
                                            <option value="url_other">{{ __('other_url') }}</option>
                                        </select>
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="required">{{ __('URL') }}</label>
                                        <input type="url" name="url" id="edit_url" class="form-control" placeholder="URL" required>
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('image') }} / Logo</label>
                                        <input name="file" type="file" class="filepond" accept="image/*">
                                        <div id="current_image_preview" class="mt-2"></div>
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label class="mr-2">{{ __('schema_markup') }}</label>
                                        <input type="text" name="schema_markup" class="form-control" id="edit_schema_markup" placeholder="{{ __('schema_markup') }}">
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('meta_keywords') }}</label>
                                        <input id="edit_meta_tags" style="border-radius: 0.25rem" class="w-100" type="text" name="meta_keyword" placeholder="{{ __('press_enter_add_keywords') }}">
                                    </div>

                                    <div class="form-group col-md-6 col-sm-12">
                                        <label>{{ __('meta_title') }}</label>
                                        <input type="text" name="meta_title" class="form-control" id="edit_meta_title" placeholder="{{ __('meta_title') }}">
                                    </div>

                                    <div class="form-group col-md-12 col-sm-12">
                                        <label>{{ __('meta_description') }}</label>
                                        <textarea id="edit_meta_description" name="meta_description" class="form-control"></textarea>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="modal-footer">
                                <button type="button" class="btn btn-default" data-dismiss="modal">{{ __('close') }}</button>
                                <button type="submit" class="btn btn-primary">{{ __('submit') }}</button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>
@endsection

@section('script')
<script type="text/javascript">
    // Düzenleme butonuna tıklanınca
    window.actionEvents = {
        'click .edit-data': function(e, value, row, index) {
            // Form action URL'ini ayarla
            $('#update_form').attr('action', '{{ url("live_streaming") }}/' + row.id);
            
            // Alanları doldur
            $('#edit_id').val(row.id);
            $("#edit_language").val(row.language_id);
            $("#edit_title").val(row.title);
            $('#edit_type').val(row.type1);
            $('#edit_url').val(row.url_raw);
            $('#edit_meta_tags').val(row.meta_keyword);
            $('#edit_schema_markup').val(row.schema_markup);
            $('#edit_meta_description').val(row.meta_description);
            $('#edit_meta_title').val(row.meta_title);
            
            // Mevcut resmi göster
            if (row.image_url && row.image_url != '') {
                $('#current_image_preview').html('<img src="' + row.image_url + '" height="60" class="rounded" style="object-fit: cover;"><br><small class="text-muted">Mevcut resim</small>');
            } else {
                $('#current_image_preview').html('<small class="text-muted">Resim yok</small>');
            }
        }
    };

    function queryParams(p) {
        return {
            sort: p.sort,
            order: p.order,
            limit: p.limit,
            offset: p.offset,
            search: p.search,
            language_id: $('#filter_language_id').val(),
        };
    }

    $("#filter_language_id").on("change", function() {
        $('#table').bootstrapTable('refresh');
    });
</script>
@endsection
