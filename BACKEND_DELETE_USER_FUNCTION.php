// ============================================================
// LARAVEL BACKEND - ApiController.php içine eklenecek fonksiyon
// ============================================================

/**
 * Kullanıcı hesabını sil (Soft Delete)
 * 
 * @param Request $request
 * @return JsonResponse
 */
public function deleteUser(Request $request)
{
    try {
        // Validasyon
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'error' => true,
                'message' => 'user_id parametresi gereklidir',
                'data' => null
            ], 400);
        }

        $userId = $request->input('user_id');

        // Kullanıcıyı bul
        $user = DB::table('tbl_users')
            ->where('id', $userId)
            ->orWhere('firebase_uid', $userId)
            ->first();

        if (!$user) {
            return response()->json([
                'error' => true,
                'message' => 'Kullanıcı bulunamadı',
                'data' => null
            ], 404);
        }

        // Soft Delete - status'u 0 yap
        DB::table('tbl_users')
            ->where('id', $user->id)
            ->update([
                'status' => 0,
                'deleted_at' => now(),
                'updated_at' => now()
            ]);

        // Log kaydı (opsiyonel)
        Log::info('User account deleted (soft delete)', [
            'user_id' => $user->id,
            'email' => $user->email,
            'deleted_at' => now()
        ]);

        return response()->json([
            'error' => false,
            'message' => 'Hesap başarıyla silindi',
            'data' => [
                'user_id' => $user->id,
                'deleted_at' => now()->toDateTimeString()
            ]
        ], 200);

    } catch (\Exception $e) {
        Log::error('Delete user error: ' . $e->getMessage());
        
        return response()->json([
            'error' => true,
            'message' => 'Hesap silinirken bir hata oluştu: ' . $e->getMessage(),
            'data' => null
        ], 500);
    }
}

// ============================================================
// LARAVEL BACKEND - routes/api.php içine eklenecek route
// ============================================================

// Hesap silme endpoint'i (Auth middleware olmadan)
Route::post('delete_user', [ApiController::class, 'deleteUser']);

// Eğer auth middleware ile korumak isterseniz:
// Route::middleware('auth:sanctum')->post('delete_user', [ApiController::class, 'deleteUser']);

// ============================================================
// NOTLAR:
// ============================================================
// 1. ApiController.php dosyasının başına şu import'ları ekleyin:
//    use Illuminate\Support\Facades\Validator;
//    use Illuminate\Support\Facades\DB;
//    use Illuminate\Support\Facades\Log;
//    use Illuminate\Http\JsonResponse;
//
// 2. tbl_users tablosunda 'deleted_at' kolonu yoksa migration ile ekleyin:
//    Schema::table('tbl_users', function (Blueprint $table) {
//        $table->timestamp('deleted_at')->nullable();
//    });
//
// 3. Status değerleri:
//    - 1: Aktif kullanıcı
//    - 0: Silinmiş kullanıcı (Soft Delete)
//
// 4. Hard Delete yapmak isterseniz (önerilmez):
//    DB::table('tbl_users')->where('id', $user->id)->delete();
//
// 5. İlişkili verileri de silmek isterseniz:
//    DB::table('tbl_user_saved_news')->where('user_id', $user->id)->delete();
//    DB::table('tbl_user_followed_categories')->where('user_id', $user->id)->delete();
//
// ============================================================
