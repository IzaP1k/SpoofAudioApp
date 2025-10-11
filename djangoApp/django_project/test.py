from django.http import HttpResponse

def test_fun(request):
    return HttpResponse("test completed")
