@extends('layouts.main')

@section('title', 'Basit Bildirim Gönder')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-md-8 offset-md-2">
            <div class="card shadow">
                <div class="card-header bg-primary text-white">
                    <h4 class="mb-0">
                        <i class="fas fa-bell"></i> Basit Bildirim Gönder
                    </h4>
                </div>
                <div class="card-body">
                    
                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible fade show">
                            <i class="fas fa-check-circle"></i> {{ session('success') }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    @endif
                    
                    @if(session('error'))
                        <div class="alert alert-danger alert-dismissible fade show">
                            <i class="fas fa-exclamation-circle"></i> {{ session('error') }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    @endif
                    
                    <form action="{{ route('simple-notification.send') }}" method="POST">
                        @csrf
                        
                        <div class="mb-3">
                            <label for="title" class="form-label"><strong>Başlık</strong></label>
                            <input type="text" 
                                   name="title" 
                                   id="title" 
                                   class="form-control @error('title') is-invalid @enderror" 
                                   placeholder="🔴 Son Dakika"
                                   value="{{ old('title') }}"
                                   maxlength="100"
                                   required>
                            @error('title')
                                <div class="invalid-feedback">{{ $message }}</div>
                            @enderror
                        </div>
                        
                        <div class="mb-3">
                            <label for="body" class="form-label"><strong>Mesaj</strong></label>
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
                        </div>
                        
                        <div class="mb-3">
                            <label for="topic" class="form-label"><strong>Topic</strong></label>
                            <select name="topic" id="topic" class="form-control">
                                <option value="Turkish" selected>Turkish (Tüm Türk kullanıcılar)</option>
                                <option value="all_users">all_users</option>
                                <option value="newsly_important">newsly_important (Önemli)</option>
                            </select>
                            <small class="text-muted">Hangi gruba gönderilecek</small>
                        </div>
                        
                        <hr>
                        
                        <div class="alert alert-info">
                            <i class="fas fa-info-circle"></i>
                            <strong>Not:</strong> Bu bildirim seçilen topic'e abone olan tüm kullanıcılara gönderilecektir.
                        </div>
                        
                        <button type="submit" class="btn btn-primary btn-lg w-100">
                            <i class="fas fa-paper-plane"></i> Bildirim Gönder
                        </button>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
