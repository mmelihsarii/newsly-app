{{-- 
    Bildirim Gönderme Sayfası
    
    Bu dosyayı Laravel projesine kopyala:
    resources/views/notification.blade.php
--}}

@extends('layouts.app')

@section('content')
<div class="container-fluid">
    <div class="row justify-content-center">
        <div class="col-md-8 col-lg-6">
            <div class="card shadow">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">
                        <i class="fas fa-bell"></i> Bildirim Gönder
                    </h4>
                </div>
                <div class="card-body">
                    
                    {{-- Başarı Mesajı --}}
                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible fade show" role="alert">
                            <i class="fas fa-check-circle"></i> {{ session('success') }}
                            <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                    @endif
                    
                    {{-- Hata Mesajı --}}
                    @if(session('error'))
                        <div class="alert alert-danger alert-dismissible fade show" role="alert">
                            <i class="fas fa-exclamation-circle"></i> {{ session('error') }}
                            <button type="button" class="close" data-dismiss="alert" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                        </div>
                    @endif
                    
                    <form action="{{ route('notification.send') }}" method="POST">
                        @csrf
                        
                        {{-- Başlık --}}
                        <div class="form-group">
                            <label for="title"><strong>Başlık *</strong></label>
                            <input type="text" 
                                   name="title" 
                                   id="title" 
                                   class="form-control form-control-lg @error('title') is-invalid @enderror" 
                                   placeholder="🔴 Son Dakika"
                                   value="{{ old('title') }}"
                                   maxlength="100"
                                   required>
                            @error('title')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                            <small class="text-muted">Maksimum 100 karakter</small>
                        </div>
                        
                        {{-- Mesaj --}}
                        <div class="form-group">
                            <label for="body"><strong>Mesaj *</strong></label>
                            <textarea name="body" 
                                      id="body" 
                                      class="form-control @error('body') is-invalid @enderror" 
                                      rows="4"
                                      placeholder="Bildirim mesajınızı yazın..."
                                      maxlength="500"
                                      required>{{ old('body') }}</textarea>
                            @error('body')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                            <small class="text-muted">Maksimum 500 karakter</small>
                        </div>
                        
                        {{-- Haber Linki --}}
                        <div class="form-group">
                            <label for="url"><strong>Haber Linki</strong> <span class="text-muted">(Opsiyonel)</span></label>
                            <input type="url" 
                                   name="url" 
                                   id="url" 
                                   class="form-control" 
                                   placeholder="https://www.example.com/haber/..."
                                   value="{{ old('url') }}">
                            <small class="text-muted">Kullanıcı bildirime tıklayınca bu sayfaya yönlendirilir</small>
                        </div>
                        
                        <hr>
                        
                        {{-- Uyarı --}}
                        <div class="alert alert-warning">
                            <i class="fas fa-exclamation-triangle"></i>
                            <strong>Dikkat:</strong> Bu bildirim <u>tüm uygulama kullanıcılarına</u> gönderilecektir.
                            Lütfen gereksiz bildirim göndermekten kaçının.
                        </div>
                        
                        {{-- Gönder Butonu --}}
                        <button type="submit" class="btn btn-primary btn-lg btn-block">
                            <i class="fas fa-paper-plane"></i> Bildirim Gönder
                        </button>
                    </form>
                </div>
                
                <div class="card-footer text-muted text-center">
                    <small>Bildirimler Firebase Cloud Messaging üzerinden gönderilir</small>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
