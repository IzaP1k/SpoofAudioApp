import torch
import numpy as np
from captum.attr import Occlusion
from pytorch_grad_cam import GradCAMPlusPlus
from pytorch_grad_cam.utils.model_targets import ClassifierOutputTarget
from xai.prepare_visual_descrip import generate_human_friendly_explanation, plot_xai_to_base64


def compute_xai_attributes(model, input_tensor, target_class):

    target_layers = [model.residual_blocks[5]] if hasattr(model, 'residual_blocks') else [list(model.children())[-2]]
    targets = [ClassifierOutputTarget(target_class)]

    with GradCAMPlusPlus(model=model, target_layers=target_layers) as cam:
        grayscale_cam = cam(input_tensor=input_tensor, targets=targets)
        attr_gc = grayscale_cam[0, :]

    occlusion = Occlusion(model)
    attr_occ = occlusion.attribute(input_tensor,
                                   strides=(1, 4, 4),
                                   target=target_class,
                                   sliding_window_shapes=(1, 15, 15),
                                   baselines=0)

    attr_occ_upsampled = torch.nn.functional.interpolate(
        attr_occ, size=input_tensor.shape[2:], mode='bilinear', align_corners=False
    )

    return attr_gc, attr_occ_upsampled.detach().cpu().numpy()[0, 0]

def run_xai_analysis(model, list_instances, list_scores, device='cpu'):

    expl_descrip = (f"Pierwsza grafika to spektrogram Mel – wizualizacja dźwięku w czasie, dostosowana do specyfiki "
                    f"ludzkiego słuchu. Kolejne dwa obrazy to mapy cieplne, które wskazują, na których fragmentach "
                    f"nagrania model skupił się najbardziej podczas podejmowania decyzji. Szczegółowa interpretacja "
                    f"słowna znajduje się poniżej:")

    model.eval()
    model.to(device)

    images_base64 = []
    explanations = []

    for i, (instance_data, score) in enumerate(zip(list_instances, list_scores)):
        input_tensor = torch.tensor(instance_data, dtype=torch.float32).to(device)
        if input_tensor.ndim == 3:
            input_tensor = input_tensor.unsqueeze(0)

        target_class = 1 if score > 0.5 else 0

        try:
            gradcam, occ = compute_xai_attributes(model, input_tensor, target_class)
            expl_gradcam = generate_human_friendly_explanation(gradcam, method_name="Grad-CAM")
            expl_occ = generate_human_friendly_explanation(occ, method_name="Occlusion")
            full_explanation = f"{expl_descrip}\n\n{expl_gradcam}\n\n{expl_occ}"
            explanations.append(full_explanation)

            original_img = input_tensor.detach().cpu().numpy()[0, 0]
            title = f"Analiza fragmentu {i + 1} (Pewność: {score:.2f})"
            img_b64 = plot_xai_to_base64(original_img, gradcam, occ, title)
            images_base64.append(img_b64)

        except Exception as e:
            print(f"Błąd XAI dla fragmentu {i}: {e}")

            continue

    return {
        "images": images_base64,
        "info": explanations
    }