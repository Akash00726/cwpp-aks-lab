kubectl get secret argocd-initial-admin-secret `
>> -n argocd `
>> -o jsonpath="{.data.password}" | `
>> % { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
T0xFvV2DQLEMn267